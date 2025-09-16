const express = require('express');
const { body, param } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

// Get subscription plans
router.get('/plans', asyncHandler(async (req, res) => {
  const plans = [
    {
      id: 'free',
      name: 'Free',
      nameSomali: 'Bilaash',
      price: 0,
      currency: 'USD',
      features: [
        'Access to free books',
        'Basic reading features',
        'Limited offline downloads'
      ],
      featuresSomali: [
        'Furaha buugagta bilaashka ah',
        'Astaamaha akhrinta aasaasiga ah',
        'Soo dejinta xadidan oo offline ah'
      ]
    },
    {
      id: 'premium_monthly',
      name: 'Premium Monthly',
      nameSomali: 'Premium Bilaha',
      price: 9.99,
      currency: 'USD',
      billingCycle: 'monthly',
      features: [
        'Access to all books',
        'Unlimited offline downloads',
        'Advanced reading features',
        'Priority customer support',
        'Ad-free experience'
      ],
      featuresSomali: [
        'Furaha dhammaan buugagta',
        'Soo dejinta unlimited ah oo offline ah',
        'Astaamaha akhrinta horumarsan',
        'Taageero macaamiisha oo priority ah',
        'Khibrada aan ads lahayn'
      ]
    },
    {
      id: 'premium_yearly',
      name: 'Premium Yearly',
      nameSomali: 'Premium Sanadka',
      price: 99.99,
      currency: 'USD',
      billingCycle: 'yearly',
      savings: 'Save 17%',
      savingsSomali: 'Kaydi 17%',
      features: [
        'Access to all books',
        'Unlimited offline downloads',
        'Advanced reading features',
        'Priority customer support',
        'Ad-free experience',
        'Early access to new features'
      ],
      featuresSomali: [
        'Furaha dhammaan buugagta',
        'Soo dejinta unlimited ah oo offline ah',
        'Astaamaha akhrinta horumarsan',
        'Taageero macaamiisha oo priority ah',
        'Khibrada aan ads lahayn',
        'Furaha horumarsan oo cusub'
      ]
    },
    {
      id: 'lifetime',
      name: 'Lifetime',
      nameSomali: 'Nololka oo dhammeystiran',
      price: 299.99,
      currency: 'USD',
      billingCycle: 'one-time',
      features: [
        'Access to all books forever',
        'Unlimited offline downloads',
        'Advanced reading features',
        'Priority customer support',
        'Ad-free experience',
        'All future updates included',
        'Family sharing (up to 5 accounts)'
      ],
      featuresSomali: [
        'Furaha dhammaan buugagta weligeed',
        'Soo dejinta unlimited ah oo offline ah',
        'Astaamaha akhrinta horumarsan',
        'Taageero macaamiisha oo priority ah',
        'Khibrada aan ads lahayn',
        'Dhammaan cusbooneysiinta mustaqbalka',
        'Wadaagga qoyska (ilaa 5 account)'
      ]
    }
  ];
  
  res.json({ plans });
}));

// Get current user subscription
router.get('/subscription', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  const subscription = await db('subscriptions')
    .where('user_id', userId)
    .whereIn('status', ['active', 'pending'])
    .orderBy('created_at', 'desc')
    .first();
  
  if (!subscription) {
    return res.json({
      hasSubscription: false,
      currentPlan: 'free'
    });
  }
  
  // Check if subscription is expired
  let isActive = subscription.status === 'active';
  if (subscription.end_date && new Date() > new Date(subscription.end_date)) {
    isActive = false;
    // Update subscription status
    await db('subscriptions')
      .where('id', subscription.id)
      .update({ status: 'expired' });
  }
  
  // Update user's subscription plan
  await db('users')
    .where('id', userId)
    .update({
      subscription_plan: isActive ? subscription.plan_type : 'free',
      subscription_expires_at: subscription.end_date
    });
  
  res.json({
    hasSubscription: isActive,
    currentPlan: isActive ? subscription.plan_type : 'free',
    subscription: {
      id: subscription.id,
      planType: subscription.plan_type,
      status: isActive ? 'active' : 'expired',
      startDate: subscription.start_date,
      endDate: subscription.end_date,
      amount: subscription.amount,
      currency: subscription.currency,
      autoRenew: subscription.auto_renew
    }
  });
}));

// Create subscription (Stripe)
router.post('/create-subscription', asyncHandler(async (req, res) => {
  const { planId, paymentMethodId } = req.body;
  const userId = req.userId;
  
  if (!planId || !paymentMethodId) {
    return res.status(400).json({ 
      error: 'Plan ID and payment method are required',
      code: 'MISSING_FIELDS'
    });
  }
  
  // Validate plan
  const validPlans = ['premium_monthly', 'premium_yearly', 'lifetime'];
  if (!validPlans.includes(planId)) {
    return res.status(400).json({ 
      error: 'Invalid plan ID',
      code: 'INVALID_PLAN'
    });
  }
  
  // Get user
  const user = await db('users').where('id', userId).first();
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  // Check if user already has an active subscription
  const existingSubscription = await db('subscriptions')
    .where('user_id', userId)
    .whereIn('status', ['active', 'pending'])
    .first();
  
  if (existingSubscription) {
    return res.status(400).json({ 
      error: 'User already has an active subscription',
      code: 'SUBSCRIPTION_EXISTS'
    });
  }
  
  try {
    // Initialize Stripe (you'll need to add Stripe SDK)
    // const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    
    // For now, we'll simulate the subscription creation
    const planDetails = {
      premium_monthly: { amount: 999, interval: 'month' },
      premium_yearly: { amount: 9999, interval: 'year' },
      lifetime: { amount: 29999, interval: 'one-time' }
    };
    
    const plan = planDetails[planId];
    
    // Create subscription record
    const [subscriptionId] = await db('subscriptions').insert({
      user_id: userId,
      plan_type: planId.replace('_monthly', '').replace('_yearly', ''),
      status: 'pending',
      amount: plan.amount / 100, // Convert from cents
      currency: 'USD',
      payment_method: 'stripe',
      start_date: new Date(),
      end_date: planId === 'lifetime' ? null : 
                planId === 'premium_monthly' ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) :
                new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      auto_renew: planId !== 'lifetime'
    }).returning('id');
    
    // TODO: Integrate with actual Stripe API
    // const subscription = await stripe.subscriptions.create({
    //   customer: customer.id,
    //   items: [{ price: planId }],
    //   payment_behavior: 'default_incomplete',
    //   payment_settings: { save_default_payment_method: 'on_subscription' },
    //   expand: ['latest_invoice.payment_intent'],
    // });
    
    logger.info('Subscription created:', { userId, planId, subscriptionId });
    
    res.status(201).json({
      message: 'Subscription created successfully',
      subscriptionId,
      status: 'pending',
      requiresAction: false // Set to true if Stripe requires additional action
    });
    
  } catch (error) {
    logger.error('Subscription creation failed:', error);
    
    // Clean up failed subscription
    await db('subscriptions')
      .where('id', subscriptionId)
      .del();
    
    res.status(500).json({ 
      error: 'Failed to create subscription',
      code: 'SUBSCRIPTION_CREATION_FAILED'
    });
  }
}));

// Cancel subscription
router.post('/cancel-subscription', asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const userId = req.userId;
  
  // Get active subscription
  const subscription = await db('subscriptions')
    .where('user_id', userId)
    .where('status', 'active')
    .first();
  
  if (!subscription) {
    return res.status(404).json({ 
      error: 'No active subscription found',
      code: 'NO_SUBSCRIPTION'
    });
  }
  
  try {
    // TODO: Cancel with Stripe
    // const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    // await stripe.subscriptions.update(subscription.stripe_subscription_id, {
    //   cancel_at_period_end: true
    // });
    
    // Update subscription status
    await db('subscriptions')
      .where('id', subscription.id)
      .update({
        status: 'cancelled',
        cancelled_at: new Date(),
        cancellation_reason: reason,
        auto_renew: false
      });
    
    // Update user subscription plan
    await db('users')
      .where('id', userId)
      .update({
        subscription_plan: 'free',
        subscription_expires_at: subscription.end_date
      });
    
    logger.info('Subscription cancelled:', { userId, subscriptionId: subscription.id, reason });
    
    res.json({
      message: 'Subscription cancelled successfully',
      effectiveDate: subscription.end_date
    });
    
  } catch (error) {
    logger.error('Subscription cancellation failed:', error);
    res.status(500).json({ 
      error: 'Failed to cancel subscription',
      code: 'CANCELLATION_FAILED'
    });
  }
}));

// Reactivate subscription
router.post('/reactivate-subscription', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  // Get cancelled subscription
  const subscription = await db('subscriptions')
    .where('user_id', userId)
    .where('status', 'cancelled')
    .orderBy('created_at', 'desc')
    .first();
  
  if (!subscription) {
    return res.status(404).json({ 
      error: 'No cancelled subscription found',
      code: 'NO_CANCELLED_SUBSCRIPTION'
    });
  }
  
  try {
    // TODO: Reactivate with Stripe
    // const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    // await stripe.subscriptions.update(subscription.stripe_subscription_id, {
    //   cancel_at_period_end: false
    // });
    
    // Reactivate subscription
    await db('subscriptions')
      .where('id', subscription.id)
      .update({
        status: 'active',
        cancelled_at: null,
        cancellation_reason: null,
        auto_renew: true
      });
    
    // Update user subscription plan
    await db('users')
      .where('id', userId)
      .update({
        subscription_plan: subscription.plan_type,
        subscription_expires_at: subscription.end_date
      });
    
    logger.info('Subscription reactivated:', { userId, subscriptionId: subscription.id });
    
    res.json({
      message: 'Subscription reactivated successfully'
    });
    
  } catch (error) {
    logger.error('Subscription reactivation failed:', error);
    res.status(500).json({ 
      error: 'Failed to reactivate subscription',
      code: 'REACTIVATION_FAILED'
    });
  }
}));

// Get payment history
router.get('/history', asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const userId = req.userId;
  
  const offset = (page - 1) * limit;
  
  // Get payment history
  const payments = await db('subscriptions')
    .where('user_id', userId)
    .select(
      'id', 'plan_type', 'status', 'amount', 'currency',
      'start_date', 'end_date', 'created_at'
    )
    .orderBy('created_at', 'desc')
    .limit(limit)
    .offset(offset);
  
  // Get total count
  const totalCount = await db('subscriptions')
    .where('user_id', userId)
    .count('* as count')
    .first();
  
  res.json({
    payments,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount.count,
      totalPages: Math.ceil(totalCount.count / limit)
    }
  });
}));

// Webhook handler for Stripe events
router.post('/webhook/stripe', asyncHandler(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  
  try {
    // TODO: Verify webhook signature
    // const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    // const event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
    
    // For now, we'll just log the webhook
    logger.info('Stripe webhook received:', { 
      signature: sig,
      body: req.body 
    });
    
    // Process different event types
    // switch (event.type) {
    //   case 'customer.subscription.created':
    //     // Handle subscription creation
    //     break;
    //   case 'customer.subscription.updated':
    //     // Handle subscription updates
    //     break;
    //   case 'customer.subscription.deleted':
    //     // Handle subscription deletion
    //     break;
    //   case 'invoice.payment_succeeded':
    //     // Handle successful payment
    //     break;
    //   case 'invoice.payment_failed':
    //     // Handle failed payment
    //     break;
    // }
    
    res.json({ received: true });
    
  } catch (error) {
    logger.error('Webhook signature verification failed:', error);
    res.status(400).json({ error: 'Webhook signature verification failed' });
  }
}));

// Get subscription usage
router.get('/usage', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  // Get current subscription
  const subscription = await db('subscriptions')
    .where('user_id', userId)
    .whereIn('status', ['active', 'pending'])
    .first();
  
  if (!subscription) {
    return res.json({
      plan: 'free',
      limits: {
        offlineDownloads: 5,
        premiumBooks: 0
      },
      usage: {
        offlineDownloads: 0,
        premiumBooks: 0
      }
    });
  }
  
  // Get usage statistics
  const [downloadCount, premiumBookCount] = await Promise.all([
    db('user_library')
      .where('user_id', userId)
      .where('is_downloaded', true)
      .count('* as count')
      .first(),
    
    db('user_library as ul')
      .join('books as b', 'ul.book_id', 'b.id')
      .where('ul.user_id', userId)
      .where('b.is_free', false)
      .count('* as count')
      .first()
  ]);
  
  const limits = {
    offlineDownloads: subscription.plan_type === 'lifetime' ? -1 : 100,
    premiumBooks: subscription.plan_type === 'free' ? 0 : -1
  };
  
  res.json({
    plan: subscription.plan_type,
    limits,
    usage: {
      offlineDownloads: downloadCount.count,
      premiumBooks: premiumBookCount.count
    }
  });
}));

module.exports = router;
