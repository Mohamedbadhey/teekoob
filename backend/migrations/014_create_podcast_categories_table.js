exports.up = function(knex) {
  return knex.schema.createTable('podcast_categories', function(table) {
    table.string('id', 36).primary();
    table.string('podcast_id', 36).notNullable();
    table.string('category_id', 36).notNullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    
    // Foreign key constraints
    table.foreign('podcast_id').references('id').inTable('podcasts').onDelete('CASCADE');
    table.foreign('category_id').references('id').inTable('categories').onDelete('CASCADE');
    
    // Indexes
    table.index(['podcast_id']);
    table.index(['category_id']);
    
    // Unique constraint to prevent duplicate category assignments
    table.unique(['podcast_id', 'category_id']);
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('podcast_categories');
};
