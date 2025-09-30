exports.up = function(knex) {
  return knex.schema.createTable('notification_preferences', function(table) {
    table.increments('id').primary();
    table.integer('user_id').unsigned().notNullable().unique();
    table.boolean('random_books_enabled').defaultTo(false);
    table.integer('random_books_interval').defaultTo(10); // minutes
    table.string('platform', 50).defaultTo('mobile');
    table.boolean('daily_reminders_enabled').defaultTo(false);
    table.time('daily_reminder_time').defaultTo('20:00:00');
    table.boolean('new_book_notifications_enabled').defaultTo(true);
    table.boolean('progress_reminders_enabled').defaultTo(false);
    table.integer('progress_reminder_interval').defaultTo(7); // days
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Foreign key constraint
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Indexes for better performance
    table.index('user_id');
    table.index('random_books_enabled');
    table.index('daily_reminders_enabled');
    table.index('new_book_notifications_enabled');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('notification_preferences');
};
