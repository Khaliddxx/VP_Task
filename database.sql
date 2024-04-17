-- Here are the commands for SQL initialization


CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    gender VARCHAR(10),
    location VARCHAR(100),
    university VARCHAR(100),
    interests TEXT -- storing as JSON array or a comma-separated list
);


SELECT *, (
    -- Weights: Location = 3, University = 2, Shared Interests = 1 per match
    (CASE WHEN location = $1 THEN 3 ELSE 0 END) +
    (CASE WHEN university = $2 THEN 2 ELSE 0 END) +
    (SELECT COUNT(*) FROM unnest(string_to_array($3, ',')) AS interest
     WHERE interest = ANY(string_to_array(interests, ','))) 
) AS relevance_score
FROM users
WHERE id != $4 AND gender = $5 -- assuming you might want to filter by gender or other preferences
ORDER BY relevance_score DESC, RANDOM()
LIMIT 10;


-- Here is a javascript function for getting the recommendations, can be used for further routing conventions
const { Pool } = require('pg');
const pool = new Pool(); // Configuration might include user, password, database, host, etc.

const getRecommendations = async (userId, location, university, interests, genderPreference) => {
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
        const res = await pool.query(query, values);
        return res.rows;
    } catch (err) {
        console.error('Error executing recommendation query:', err);
        return [];
    }
};