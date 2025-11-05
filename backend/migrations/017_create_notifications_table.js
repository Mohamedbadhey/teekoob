exports.up = function(knex) {
  return knex.schema.createTable('notifications', function(table) {
    table.string('id', 36).primary();
    table.string('user_id', 36).notNullable().comment('User who receives the notification');
    table.string('sender_id', 36).nullable().comment('Admin/user who sent the notification (null for system)');
    table.string('title', 255).notNullable().comment('Notification title');
    table.text('message').notNullable().comment('Notification message content');
    table.enum('type', ['admin_message', 'system', 'book_update', 'podcast_update']).defaultTo('admin_message').comment('Notification type');
    table.boolean('is_read').defaultTo(false).comment('Whether the notification has been read');
    table.string('action_url', 500).nullable().comment('Optional URL to navigate when notification is clicked');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('read_at').nullable().comment('When the notification was read');
    
    // Foreign key constraints
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    table.foreign('sender_id').references('id').inTable('users').onDelete('SET NULL');
    
    // Indexes for efficient queries
    table.index(['user_id'], 'idx_notifications_user_id');
    table.index(['is_read'], 'idx_notifications_is_read');
    table.index(['created_at'], 'idx_notifications_created_at');
    table.index(['user_id', 'is_read'], 'idx_notifications_user_read');
    table.index(['type'], 'idx_notifications_type');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('notifications');
};

