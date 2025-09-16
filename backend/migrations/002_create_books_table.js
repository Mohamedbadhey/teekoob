exports.up = function(knex) {
  return knex.schema.createTable('books', function(table) {
    table.string('id', 36).primary();
    table.string('title', 500).notNullable();
    table.string('title_somali', 500).notNullable();
    table.text('description').notNullable();
    table.text('description_somali').notNullable();
    table.json('authors').notNullable();
    table.json('authors_somali').notNullable();
    table.string('genre', 100).notNullable();
    table.string('genre_somali', 100).notNullable();
    table.enum('language', ['en', 'so', 'ar']).notNullable();
    table.enum('format', ['ebook', 'audiobook', 'both']).notNullable();
    table.string('cover_image_url', 500);
    table.string('audio_url', 500);
    table.string('ebook_url', 500);
    table.string('sample_url', 500);
    table.integer('duration').comment('Duration in minutes');
    table.integer('page_count');
    table.decimal('rating', 3, 2);
    table.integer('review_count').defaultTo(0);
    table.boolean('is_featured').defaultTo(false);
    table.boolean('is_new_release').defaultTo(false);
    table.boolean('is_premium').defaultTo(false);
    table.json('metadata');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes
    table.index(['language']);
    table.index(['format']);
    table.index(['genre']);
    table.index(['is_featured']);
    table.index(['is_new_release']);
    table.index(['is_premium']);
    table.index(['created_at']);
    
    // Full-text search index
    table.fulltext(['title', 'title_somali', 'description', 'description_somali'], 'books_search_idx');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('books');
};
