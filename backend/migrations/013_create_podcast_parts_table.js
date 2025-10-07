exports.up = function(knex) {
  return knex.schema.createTable('podcast_parts', function(table) {
    table.string('id', 36).primary();
    table.string('podcast_id', 36).notNullable();
    table.string('title', 500).notNullable();
    table.string('title_somali', 500).notNullable();
    table.text('description').notNullable();
    table.text('description_somali').notNullable();
    table.integer('episode_number').notNullable();
    table.integer('season_number').defaultTo(1);
    table.integer('duration').comment('Duration in minutes');
    table.string('audio_url', 500);
    table.string('transcript_url', 500);
    table.text('transcript_content');
    table.json('show_notes');
    table.json('chapters');
    table.decimal('rating', 3, 2).defaultTo(0);
    table.integer('play_count').defaultTo(0);
    table.integer('download_count').defaultTo(0);
    table.boolean('is_featured').defaultTo(false);
    table.boolean('is_premium').defaultTo(false);
    table.boolean('is_free').defaultTo(true);
    table.timestamp('published_at');
    table.json('metadata');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now()).onUpdate(knex.fn.now());
    
    // Foreign key constraint
    table.foreign('podcast_id').references('id').inTable('podcasts').onDelete('CASCADE');
    
    // Indexes
    table.index(['podcast_id']);
    table.index(['episode_number']);
    table.index(['season_number']);
    table.index(['published_at']);
    table.index(['is_featured']);
    table.index(['is_premium']);
    table.index(['created_at']);
    
    // Unique constraint for episode number per podcast
    table.unique(['podcast_id', 'episode_number', 'season_number']);
    
    // Full-text search index
    table.fulltext(['title', 'title_somali', 'description', 'description_somali'], 'podcast_parts_search_idx');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('podcast_parts');
};
