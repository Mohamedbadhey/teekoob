exports.up = function(knex) {
  return knex.schema.createTable('reviews', function(table) {
    table.string('id', 36).primary();
    table.string('user_id', 36).notNullable();
    table.string('item_id', 36).notNullable().comment('book_id or podcast_id');
    table.enum('item_type', ['book', 'podcast']).notNullable();
    table.decimal('rating', 3, 2).notNullable().defaultTo(0).comment('Rating from 0.00 to 5.00');
    table.text('comment').nullable().comment('Optional comment/review text');
    table.boolean('is_approved').defaultTo(true).comment('For moderation');
    table.boolean('is_edited').defaultTo(false).comment('Track if review was edited');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Foreign key constraints
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    // Note: Cannot add foreign key for item_id since it can reference either books or podcasts
    // The item_type field ensures proper relationship
    
    // Indexes for efficient queries
    table.index(['user_id'], 'idx_reviews_user_id');
    table.index(['item_id'], 'idx_reviews_item_id');
    table.index(['item_type'], 'idx_reviews_item_type');
    table.index(['item_id', 'item_type'], 'idx_reviews_item'); // Composite index for filtering by item
    table.index(['rating'], 'idx_reviews_rating');
    table.index(['created_at'], 'idx_reviews_created_at');
    table.index(['is_approved'], 'idx_reviews_is_approved');
    
    // Unique constraint: one review per user per item (book or podcast)
    table.unique(['user_id', 'item_id', 'item_type'], 'unique_user_item_review');
    
    // Note: Full-text search index for comments
    // MySQL requires the table to use MyISAM or InnoDB with specific settings
    // We'll skip fulltext index for now to avoid compatibility issues
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('reviews');
};

