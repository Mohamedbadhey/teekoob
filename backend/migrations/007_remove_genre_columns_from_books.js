exports.up = function(knex) {
  return knex.schema.table('books', function(table) {
    // Remove old genre columns (categories are handled via book_categories junction table)
    table.dropColumn('genre');
    table.dropColumn('genre_somali');
  });
};

exports.down = function(knex) {
  return knex.schema.table('books', function(table) {
    // Restore old genre columns
    table.string('genre', 100).notNullable();
    table.string('genre_somali', 100).notNullable();
  });
};
