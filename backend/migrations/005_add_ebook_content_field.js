exports.up = function(knex) {
  return knex.schema.table('books', function(table) {
    table.text('ebook_content').comment('Actual text content of the ebook');
  });
};

exports.down = function(knex) {
  return knex.schema.table('books', function(table) {
    table.dropColumn('ebook_content');
  });
};
