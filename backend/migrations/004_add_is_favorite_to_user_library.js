exports.up = function(knex) {
  return knex.schema.alterTable('user_library', function(table) {
    table.boolean('is_favorite').defaultTo(false);
    table.index(['is_favorite']);
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('user_library', function(table) {
    table.dropIndex(['is_favorite']);
    table.dropColumn('is_favorite');
  });
};
