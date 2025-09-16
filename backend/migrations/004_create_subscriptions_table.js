exports.up = function(knex) {
  return knex.schema.createTable('subscriptions', function(table) {
    table.string('id', 36).primary();
    table.string('user_id', 36).notNullable();
    table.enum('plan_type', ['free', 'premium', 'lifetime']).notNullable();
    table.enum('status', ['active', 'inactive', 'cancelled', 'expired']).notNullable();
    table.decimal('amount', 10, 2).notNullable();
    table.string('currency', 3).defaultTo('USD');
    table.string('payment_method', 100);
    table.string('payment_provider', 50);
    table.string('payment_provider_subscription_id', 255);
    table.timestamp('starts_at').notNullable();
    table.timestamp('expires_at');
    table.timestamp('cancelled_at');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes
    table.index(['user_id']);
    table.index(['status']);
    table.index(['plan_type']);
    table.index(['expires_at']);
    
    // Foreign key constraint
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('subscriptions');
};
