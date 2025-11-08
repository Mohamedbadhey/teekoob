exports.up = function(knex) {
  return knex.schema.table('users', function(table) {
    table.string('reset_password_code', 6).nullable();
    table.timestamp('reset_password_code_expires_at').nullable();
    // Keep existing fields for backward compatibility (can be removed later)
    // table.string('reset_password_token', 255).nullable();
    // table.timestamp('reset_password_expires_at').nullable();
  });
};

exports.down = function(knex) {
  return knex.schema.table('users', function(table) {
    table.dropColumn('reset_password_code');
    table.dropColumn('reset_password_code_expires_at');
  });
};

