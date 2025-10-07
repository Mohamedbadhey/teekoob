exports.up = function(knex) {
  return knex.schema.createTable('podcasts', function(table) {
    table.string('id', 36).primary();
    table.string('title', 500).notNullable();
    table.string('title_somali', 500).notNullable();
    table.text('description').notNullable();
    table.text('description_somali').notNullable();
    table.string('host', 200).notNullable();
    table.string('host_somali', 200).notNullable();
    table.enum('language', ['en', 'so', 'ar']).notNullable();
    table.string('cover_image_url', 500);
    table.string('rss_feed_url', 500);
    table.string('website_url', 500);
    table.integer('total_episodes').defaultTo(0);
    table.decimal('rating', 3, 2).defaultTo(0);
    table.integer('review_count').defaultTo(0);
    table.boolean('is_featured').defaultTo(false);
    table.boolean('is_new_release').defaultTo(false);
    table.boolean('is_premium').defaultTo(false);
    table.boolean('is_free').defaultTo(true);
    table.json('metadata');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Indexes
    table.index(['language']);
    table.index(['is_featured']);
    table.index(['is_new_release']);
    table.index(['is_premium']);
    table.index(['created_at']);
    
    // Full-text search index
    table.fulltext(['title', 'title_somali', 'description', 'description_somali'], 'podcasts_search_idx');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('podcasts');
};
