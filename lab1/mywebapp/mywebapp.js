const express = require("express");
const minimist = require("minimist");
const pool = require("./db");

const app = express();
const args = minimist(process.argv.slice(2));
const PORT = args.port || 8000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/health/alive", (req, res) => {
  res.status(200).send("OK");
});

app.get("/health/ready", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).send("OK");
  } catch (error) {
    res.status(500).send("Database connection failed: " + error.message);
  }
});

app.get("/", (req, res) => {
  if (!req.accepts("html")) {
    return res.status(406).send("Not Acceptable: Only text/html is supported");
  }

  res.type("html").send(`
        <h1>Simple Inventory API</h1>
        <ul>
            <li><a href="/items">GET /items</a> - Список усіх предметів</li>
            <li>POST /items - Створити новий запис</li>
            <li>GET /items/&lt;id&gt; - Детальна інформація по запису</li>
        </ul>
    `);
});

app.get("/items", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT id, name FROM items");

    if (req.accepts("json")) {
      res.json(rows);
    } else if (req.accepts("html")) {
      let html = '<table border="1"><tr><th>ID</th><th>Name</th></tr>';
      rows.forEach((item) => {
        html += `<tr><td>${item.id}</td><td><a href="/items/${item.id}">${item.name}</a></td></tr>`;
      });
      html += "</table>";
      res.send(html);
    } else {
      res.status(406).send("Not Acceptable");
    }
  } catch (error) {
    res.status(500).send(error.message);
  }
});

app.post("/items", async (req, res) => {
  const { name, quantity } = req.body;

  if (!name || quantity === undefined) {
    return res.status(400).send("Поля name та quantity обов'язкові");
  }

  try {
    const [result] = await pool.query(
      "INSERT INTO items (name, quantity) VALUES (?, ?)",
      [name, quantity],
    );

    if (req.accepts("json")) {
      res.status(201).json({ id: result.insertId, name, quantity });
    } else if (req.accepts("html")) {
      res.status(201).send(`
                <p>Предмет успішно додано! ID: ${result.insertId}</p>
                <a href="/items">Повернутися до списку</a>
            `);
    } else {
      res.status(406).send("Not Acceptable");
    }
  } catch (error) {
    res.status(500).send(error.message);
  }
});

app.get("/items/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const [rows] = await pool.query(
      "SELECT id, name, quantity, created_at FROM items WHERE id = ?",
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).send("Предмет не знайдено");
    }

    const item = rows[0];

    if (req.accepts("json")) {
      res.json(item);
    } else if (req.accepts("html")) {
      const html = `
                <h2>Деталі предмету</h2>
                <p><strong>ID:</strong> ${item.id}</p>
                <p><strong>Назва:</strong> ${item.name}</p>
                <p><strong>Кількість:</strong> ${item.quantity}</p>
                <p><strong>Дата створення:</strong> ${item.created_at}</p>
                <br>
                <a href="/items">Повернутися до списку</a>
            `;
      res.send(html);
    } else {
      res.status(406).send("Not Acceptable");
    }
  } catch (error) {
    res.status(500).send(error.message);
  }
});

if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS) > 0) {
  app.listen({ fd: 3 }, () => {
    console.log("Сервер mywebapp запущено через systemd socket activation");
  });
} else {
  app.listen(PORT, () => {
    console.log(`Сервер mywebapp запущено на порту ${PORT}`);
  });
}
