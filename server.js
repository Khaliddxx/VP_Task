const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const dotenv = require("dotenv").config();

const app = express();
app.use(cors()); // Enable CORS for frontend interaction

const pool = new Pool({
  connectionString: process.env.DATABASE_URI,
});

app.get(
  "/recommendations/:userId/:location/:university/:interests/:genderPreference",
  async (req, res) => {
    const { userId, location, university, interests, genderPreference } =
      req.params;
    const query = `
        SELECT *, (
            (CASE WHEN location = $1 THEN 3 ELSE 0 END) +
            (CASE WHEN university = $2 THEN 2 ELSE 0 END) +
            (SELECT COUNT(*) FROM unnest(string_to_array($3, ',')) AS interest
             WHERE interest = ANY(string_to_array(interests, ',')))
        ) AS relevance_score
        FROM users
        WHERE id != $4 AND gender = $5
        ORDER BY relevance_score DESC, RANDOM()
        LIMIT 10;
    `;
    const values = [location, university, interests, userId, genderPreference];
    try {
      const result = await pool.query(query, values);
      res.json(result.rows);
    } catch (err) {
      console.error("Error executing recommendation query:", err);
      res.status(500).send("Error executing recommendation query");
    }
  }
);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
