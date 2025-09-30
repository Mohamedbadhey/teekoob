exports.up = function(knex) {
  return knex.schema.createTable('user_fcm_tokens', function(table) {
    table.increments('id').primary();
    table.integer('user_id').unsigned().notNullable();
    table.string('fcm_token', 500).notNullable();
    table.string('platform', 50).defaultTo('mobile');
    table.boolean('enabled').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Foreign key constraint
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Unique constraint on user_id and fcm_token combination
    table.unique(['user_id', 'fcm_token']);
    
    // Indexes for better performance
    table.index('user_id');
    table.index('fcm_token');
    table.index('enabled');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('user_fcm_tokens');
};
