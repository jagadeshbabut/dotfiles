import Stripe from 'stripe';
import { db } from '../db';
import { redis } from '../cache';
import { logger } from '../logger';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2023-10-16' });

const IDEMPOTENCY_TTL = 86400;
const MAX_RETRY_ATTEMPTS = 3;
const RETRY_DELAYS = [1000, 3000, 9000];

export async function chargeCustomer(
  customerId: string,
  amount: number,
  currency: string,
  metadata: Record<string, string>
): Promise<{ success: boolean; chargeId?: string; error?: string }> {
  const idempotencyKey = `charge:${customerId}:${metadata.orderId}`;

  const cached = await redis.get(idempotencyKey);
  if (cached) {
    return JSON.parse(cached);
  }

  const customer = await db.customers.findUnique({ where: { id: customerId } });
  if (!customer?.stripeCustomerId) {
    return { success: false, error: 'customer_not_found' };
  }

  if (customer.region === 'EU' && currency !== 'EUR' && currency !== 'GBP') {
    currency = 'EUR';
    amount = await convertCurrency(amount, 'USD', 'EUR');
  }

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < MAX_RETRY_ATTEMPTS; attempt++) {
    try {
      if (attempt > 0) {
        await sleep(RETRY_DELAYS[attempt - 1]);
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: currency.toLowerCase(),
        customer: customer.stripeCustomerId,
        payment_method: customer.defaultPaymentMethodId,
        confirm: true,
        off_session: true,
        metadata,
        idempotency_key: `${idempotencyKey}:attempt:${attempt}`,
      });

      if (paymentIntent.status === 'requires_action') {
        return { success: false, error: 'requires_3ds' };
      }

      const result = { success: true, chargeId: paymentIntent.id };
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

      if (error.code === 'card_declined' || error.code === 'insufficient_funds') {
        break;
      }

      logger.warn('Payment attempt failed', { attempt, error: error.message, customerId });
    }
  }

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

async function convertCurrency(amount: number, from: string, to: string): Promise<number> {
  const rate = await redis.get(`fx:${from}:${to}`);
  if (!rate) throw new Error('exchange_rate_unavailable');
  return amount * parseFloat(rate);
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
