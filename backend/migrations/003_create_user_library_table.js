exports.up = function(knex) {
  return knex.schema.createTable('user_library', function(table) {
    table.string('id', 36).primary();
    table.string('user_id', 36).notNullable();
    table.string('book_id', 36).notNullable();
    table.enum('status', ['reading', 'completed', 'wishlist', 'archived']).defaultTo('reading');
    table.decimal('progress_percentage', 5, 2).defaultTo(0.00);
    table.string('current_position', 100).comment('Current page or timestamp');
    table.json('bookmarks');
    table.json('notes');
    table.json('highlights');
    table.json('reading_preferences');
    table.json('audio_preferences');
    table.boolean('is_downloaded').defaultTo(false);
    table.timestamp('downloaded_at');
    table.timestamp('last_opened_at');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes
    table.index(['user_id']);
    table.index(['book_id']);
    table.index(['status']);
    table.index(['is_downloaded']);
    table.index(['last_opened_at']);
    
    // Unique constraint to prevent duplicate entries
    table.unique(['user_id', 'book_id']);
    
    // Foreign key constraints
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    table.foreign('book_id').references('id').inTable('books').onDelete('CASCADE');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('user_library');
};
