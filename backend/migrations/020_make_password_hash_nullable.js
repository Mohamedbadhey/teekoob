exports.up = function(knex) {
  return knex.schema.alterTable('users', function(table) {
    // Make password_hash nullable to support email verification flow
    // where user is created first, then password is set after verification
    table.string('password_hash', 255).nullable().alter();
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('users', function(table) {
    // Revert: make password_hash required again
    // Note: This will fail if there are any NULL values in the column
    table.string('password_hash', 255).notNullable().alter();
  });
};

