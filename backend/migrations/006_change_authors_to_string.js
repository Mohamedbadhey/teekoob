exports.up = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    // Change authors from JSON to string
    table.string('authors', 500).notNullable().alter();
    table.string('authors_somali', 500).notNullable().alter();
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    // Revert back to JSON
    table.json('authors').notNullable().alter();
    table.json('authors_somali').notNullable().alter();
  });
};
