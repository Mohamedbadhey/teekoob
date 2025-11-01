exports.up = function(knex) {
  return knex.schema.createTable('user_favorites', function(table) {
    // Primary key - matches users, books, podcasts id structure
    table.string('id', 36).primary();
    
    // Foreign key to users table - matches users.id structure (varchar(36))
    table.string('user_id', 36).notNullable();
    
    // Item reference - can be book_id or podcast_id
    // Both books.id and podcasts.id are varchar(36)
    table.string('item_id', 36).notNullable();
    
    // Discriminator to distinguish between books and podcasts
    table.enum('item_type', ['book', 'podcast']).notNullable();
    
    // Timestamps - matching other tables
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes for performance
    table.index(['user_id'], 'idx_user_favorites_user_id');
    table.index(['item_id'], 'idx_user_favorites_item_id');
    table.index(['item_type'], 'idx_user_favorites_item_type');
    table.index(['user_id', 'item_type'], 'idx_user_favorites_user_type');
    
    // Unique constraint to prevent duplicate favorites
    // Same user cannot favorite the same item twice
    table.unique(['user_id', 'item_id', 'item_type'], 'uk_user_favorites_unique');
    
    // Foreign key constraint to users table
    // Note: Cannot have FK to both books and podcasts due to MySQL limitation
    // The item_id and item_type combination ensures data integrity at application level
    table.foreign('user_id', 'fk_user_favorites_user_id')
      .references('id')
      .inTable('users')
      .onDelete('CASCADE');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('user_favorites');
};

