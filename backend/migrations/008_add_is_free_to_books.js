exports.up = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    table.boolean('is_free').defaultTo(false).notNullable();
    table.index(['is_free']);
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    table.dropIndex(['is_free']);
    table.dropColumn('is_free');
  });
};
