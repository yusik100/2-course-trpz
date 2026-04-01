const mysql = require("mysql2/promise");
const minimist = require("minimist");

const args = minimist(process.argv.slice(2));

const pool = mysql.createPool({
  host: args.dbhost || "127.0.0.1",
  user: args.dbuser || "root",
  password: String(args.dbpass || ""),
  database: args.dbname || "inventory",
  charset: "utf8mb4",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;
