const pool = require("./db");

async function runMigration() {
  try {
    console.log("Починаємо міграцію бд");

    const createTableQuery = `
            CREATE TABLE IF NOT EXISTS items (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                quantity INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `;

    await pool.query(createTableQuery);
    console.log('Таблиця "items" успішно створена або вже існує.');

    process.exit(0);
  } catch (error) {
    console.error("Помилка при виконанні міграції:", error.message);
    process.exit(1);
  }
}

runMigration();
