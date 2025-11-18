exports.up = function(knex) {
  return knex.schema.table('users', function(table) {
    table.string('email_verification_code', 6).nullable();
    table.timestamp('email_verification_code_expires_at').nullable();
  });
};

exports.down = function(knex) {
  return knex.schema.table('users', function(table) {
    table.dropColumn('email_verification_code');
    table.dropColumn('email_verification_code_expires_at');
  });
};

