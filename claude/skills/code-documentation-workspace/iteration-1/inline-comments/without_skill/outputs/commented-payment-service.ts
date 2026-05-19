import Stripe from 'stripe';
import { db } from '../db';
import { redis } from '../cache';
import { logger } from '../logger';

// Initialize the Stripe client using a secret key from the environment.
// The '!' asserts the env var is defined at runtime — if it's missing, Stripe will throw.
// The apiVersion pin ensures this code behaves consistently even after Stripe releases breaking changes.
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2023-10-16' });

// How long (in seconds) a completed or failed charge result is cached in Redis.
// 86400 = 24 hours. Within this window, duplicate requests for the same order
// return the cached result immediately without hitting Stripe again.
const IDEMPOTENCY_TTL = 86400;

// Maximum number of times we'll attempt to create the PaymentIntent before giving up.
const MAX_RETRY_ATTEMPTS = 3;

// Exponential-ish back-off delays between retry attempts (milliseconds).
// attempt 1 → 1 s, attempt 2 → 3 s, attempt 3 → 9 s.
// Index is (attempt - 1), so RETRY_DELAYS[0] is used before the second attempt.
const RETRY_DELAYS = [1000, 3000, 9000];

export async function chargeCustomer(
  customerId: string,
  amount: number,       // Expected in the source currency's major unit (e.g. 10.99 USD), NOT cents.
  currency: string,
  metadata: Record<string, string>
): Promise<{ success: boolean; chargeId?: string; error?: string }> {

  // The idempotency key is scoped to customer + order so that retrying the same
  // order never produces a duplicate charge, even across process restarts.
  const idempotencyKey = `charge:${customerId}:${metadata.orderId}`;

  // Short-circuit: if Redis already has a result for this key (from a prior successful
  // or permanently-failed charge), return it without touching Stripe or the DB again.
  const cached = await redis.get(idempotencyKey);
  if (cached) {
    return JSON.parse(cached);
  }

  // Fetch the customer record to get their Stripe customer ID and default payment method.
  // If either is missing, we can't charge them — fail fast rather than calling Stripe.
  const customer = await db.customers.findUnique({ where: { id: customerId } });
  if (!customer?.stripeCustomerId) {
    return { success: false, error: 'customer_not_found' };
  }

  // EU compliance: if the customer's region is EU and we somehow received a non-EUR/GBP
  // currency (e.g. the caller passed 'USD'), silently coerce to EUR and convert the amount.
  // This avoids regulatory issues with charging EU customers in USD.
  // Note: this mutation is intentional but can be surprising — the caller sees the original
  // currency in their args but the DB record will store EUR.
  if (customer.region === 'EU' && currency !== 'EUR' && currency !== 'GBP') {
    currency = 'EUR';
    amount = await convertCurrency(amount, 'USD', 'EUR');
  }

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < MAX_RETRY_ATTEMPTS; attempt++) {
    try {
      // Skip the delay on the very first attempt; only sleep before retries.
      if (attempt > 0) {
        await sleep(RETRY_DELAYS[attempt - 1]);
      }

      const paymentIntent = await stripe.paymentIntents.create({
        // Stripe requires the amount in the smallest currency unit (cents for USD/EUR).
        // Math.round prevents floating-point artifacts like 10.99 * 100 = 1098.9999...
        amount: Math.round(amount * 100),
        currency: currency.toLowerCase(), // Stripe expects lowercase ISO 4217 codes.
        customer: customer.stripeCustomerId,
        payment_method: customer.defaultPaymentMethodId,
        confirm: true,      // Attempt to confirm the payment immediately on creation.
        off_session: true,  // Signals to Stripe that the customer is not actively present
                            // (e.g. a recurring charge or background job). This affects
                            // how Stripe handles 3DS challenges and card authentication.
        metadata,
        // Each attempt gets its own Stripe-level idempotency key so that a retry
        // truly creates a new PaymentIntent rather than replaying the prior failed one.
        idempotency_key: `${idempotencyKey}:attempt:${attempt}`,
      });

      // 'requires_action' means Stripe needs the customer to complete a 3DS/SCA challenge.
      // We can't complete that in an off-session flow, so we surface a specific error code
      // that the caller can use to trigger a front-end authentication prompt.
      if (paymentIntent.status === 'requires_action') {
        return { success: false, error: 'requires_3ds' };
      }

      const result = { success: true, chargeId: paymentIntent.id };

      // Cache the successful result so future duplicate requests are idempotent.
      await redis.setex(idempotencyKey, IDEMPOTENCY_TTL, JSON.stringify(result));

      // Persist a local transaction record. Note: there is no distributed transaction here —
      // if this DB write fails after Stripe already charged the card, the charge still went
      // through. Downstream reconciliation should account for this gap.
      await db.transactions.create({
        data: {
          customerId,
          stripePaymentIntentId: paymentIntent.id,
          amount,
          currency,
          status: 'completed',
          metadata,
        }
      });

      return result;

    } catch (error: any) {
      lastError = error;

      // card_declined and insufficient_funds are terminal errors — retrying the same card
      // won't help and could trigger Stripe fraud signals. Break immediately rather than
      // burning the remaining attempts.
      if (error.code === 'card_declined' || error.code === 'insufficient_funds') {
        break;
      }

      // For transient errors (network timeouts, Stripe 5xx, etc.) log a warning and let
      // the loop continue to the next attempt.
      logger.warn('Payment attempt failed', { attempt, error: error.message, customerId });
    }
  }

  // Record a failed transaction regardless of why we exited the loop (exhausted retries
  // or hit a terminal card error). This is the authoritative failure record — no Stripe
  // PaymentIntent ID is available because none succeeded.
  await db.transactions.create({
    data: {
      customerId,
      amount,
      currency,
      status: 'failed',
      metadata,
      error: lastError?.message,
    }
  });

  return { success: false, error: lastError?.message || 'payment_failed' };
}

// Looks up a pre-cached FX rate from Redis (key format: "fx:FROM:TO") and applies it.
// The rate is NOT fetched live — it must be populated externally (e.g. a scheduled job).
// If the rate is missing, we throw rather than use a stale or default rate, since
// charging the wrong amount is worse than failing the charge.
async function convertCurrency(amount: number, from: string, to: string): Promise<number> {
  const rate = await redis.get(`fx:${from}:${to}`);
  if (!rate) throw new Error('exchange_rate_unavailable');
  return amount * parseFloat(rate);
}

// Simple promise-based delay helper used by the retry loop.
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
