import Stripe from 'stripe';
import { db } from '../db';
import { redis } from '../cache';
import { logger } from '../logger';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2023-10-16' });

// TTL for idempotency cache entries: 24 hours (in seconds).
// Matches the typical window within which a duplicate charge attempt might arrive
// (e.g. network retry, user double-submit). Entries older than this are safe to discard.
const IDEMPOTENCY_TTL = 86400;

const MAX_RETRY_ATTEMPTS = 3;

// Exponential back-off delays (ms) between retry attempts: 1s → 3s → 9s.
// First element is used between attempt 0→1, second between 1→2, etc.
// Intentionally coarse — transient Stripe failures (rate limits, timeouts) usually
// resolve within a few seconds.
const RETRY_DELAYS = [1000, 3000, 9000];

export async function chargeCustomer(
  customerId: string,
  amount: number,
  currency: string,
  metadata: Record<string, string>
): Promise<{ success: boolean; chargeId?: string; error?: string }> {
  // Key is scoped to customer + order so duplicate charge requests for the same
  // order are deduplicated even if they arrive from different service instances.
  const idempotencyKey = `charge:${customerId}:${metadata.orderId}`;

  // Short-circuit if we already processed this charge successfully.
  // Guards against duplicate calls caused by network retries or at-least-once
  // delivery from upstream message queues.
  const cached = await redis.get(idempotencyKey);
  if (cached) {
    return JSON.parse(cached);
  }

  const customer = await db.customers.findUnique({ where: { id: customerId } });
  if (!customer?.stripeCustomerId) {
    return { success: false, error: 'customer_not_found' };
  }

  // EU compliance: all EU customers must be charged in EUR or GBP.
  // If the caller passes a non-EU currency (e.g. USD), we silently coerce to EUR
  // and convert the amount. This prevents cross-border currency mismatch errors
  // from Stripe and satisfies PSD2 requirements for presentment currency.
  if (customer.region === 'EU' && currency !== 'EUR' && currency !== 'GBP') {
    currency = 'EUR';
    amount = await convertCurrency(amount, 'USD', 'EUR');
  }

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < MAX_RETRY_ATTEMPTS; attempt++) {
    try {
      // Skip the delay on the first attempt; subsequent attempts back off
      // using the pre-defined RETRY_DELAYS schedule.
      if (attempt > 0) {
        await sleep(RETRY_DELAYS[attempt - 1]);
      }

      const paymentIntent = await stripe.paymentIntents.create({
        // Stripe requires amounts in the currency's smallest unit (cents for USD/EUR).
        // Math.round avoids floating-point precision errors (e.g. $10.99 → 1099, not 1098.9999…).
        amount: Math.round(amount * 100),
        currency: currency.toLowerCase(),
        customer: customer.stripeCustomerId,
        payment_method: customer.defaultPaymentMethodId,
        confirm: true,
        // off_session: true tells Stripe this charge is happening without the customer
        // present (e.g. a subscription renewal or background job). Without this flag,
        // Stripe may apply SCA exemptions incorrectly and reject the charge.
        off_session: true,
        metadata,
        // Each retry gets a unique idempotency key so Stripe treats them as distinct
        // attempts rather than replaying the same request. Using the same key across
        // retries would cause Stripe to return the original (failed) result unchanged.
        idempotency_key: `${idempotencyKey}:attempt:${attempt}`,
      });

      // 3DS / Strong Customer Authentication is required but cannot be completed
      // server-side. Return a specific error so the caller can redirect the customer
      // to complete the authentication challenge.
      if (paymentIntent.status === 'requires_action') {
        return { success: false, error: 'requires_3ds' };
      }

      const result = { success: true, chargeId: paymentIntent.id };

      // Cache the successful result so any duplicate calls (retries, duplicate events)
      // return immediately without re-charging the customer.
      await redis.setex(idempotencyKey, IDEMPOTENCY_TTL, JSON.stringify(result));

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

      // These are deterministic failures — retrying will not help and could
      // confuse the customer (e.g. multiple failed charge notifications).
      // Break immediately and fall through to the failure path.
      if (error.code === 'card_declined' || error.code === 'insufficient_funds') {
        break;
      }

      logger.warn('Payment attempt failed', { attempt, error: error.message, customerId });
    }
  }

  // Record all failures (exhausted retries or hard stop) so they appear in
  // transaction history and can be reconciled with Stripe's dashboard.
  // Note: this runs even for hard-stop errors (card_declined etc.) — intentional.
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

// Reads the exchange rate from Redis (pre-populated by a separate FX rate sync job).
// Throws synchronously if the rate is missing — callers should treat this as a
// hard failure and not retry without a cache warm-up.
async function convertCurrency(amount: number, from: string, to: string): Promise<number> {
  const rate = await redis.get(`fx:${from}:${to}`);
  if (!rate) throw new Error('exchange_rate_unavailable');
  return amount * parseFloat(rate);
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
