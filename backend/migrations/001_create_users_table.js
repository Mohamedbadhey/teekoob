exports.up = function(knex) {
  return knex.schema.createTable('users', function(table) {
    table.string('id', 36).primary();
    table.string('email', 255).unique().notNullable();
    table.string('password_hash', 255).notNullable();
    table.string('first_name', 100).notNullable();
    table.string('last_name', 100).notNullable();
    table.string('display_name', 255);
    table.string('avatar_url', 500);
    table.enum('language_preference', ['en', 'so', 'ar']).defaultTo('en');
    table.enum('theme_preference', ['light', 'dark', 'sepia', 'night']).defaultTo('light');
    table.enum('subscription_plan', ['free', 'premium', 'lifetime']).defaultTo('free');
    table.enum('subscription_status', ['active', 'inactive', 'cancelled', 'expired']).defaultTo('active');
    table.timestamp('subscription_expires_at');
    table.boolean('is_verified').defaultTo(false);
    table.boolean('is_active').defaultTo(true);
    table.boolean('is_admin').defaultTo(false);
    table.timestamp('last_login_at');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes
    table.index(['email']);
    table.index(['subscription_status']);
    table.index(['created_at']);
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('users');
};
