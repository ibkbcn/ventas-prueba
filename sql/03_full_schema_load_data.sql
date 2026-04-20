-- ============================================================
-- Revenue Analysis — Schema Completo + Carga de Datos
-- ============================================================
-- Define el modelo relacional completo del proyecto e importa
-- los datos desde CSVs multi-país (US, CA, UK).
-- Incluye análisis de estado de tarjetas con window functions.
-- ============================================================

CREATE DATABASE IF NOT EXISTS sprint4;
USE sprint4;


-- ── Definición del modelo relacional ────────────────────────

CREATE TABLE IF NOT EXISTS user (
    id          VARCHAR(5)   PRIMARY KEY,
    name        VARCHAR(10),
    surname     VARCHAR(15),
    phone       VARCHAR(20),
    email       VARCHAR(50),
    birth_date  VARCHAR(20),
    country     VARCHAR(20),
    city        VARCHAR(30),
    postal_code VARCHAR(15),
    address     VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS credit_card (
    id            VARCHAR(10) PRIMARY KEY,
    user_id       VARCHAR(5),
    iban          VARCHAR(50),
    pan           VARCHAR(50),
    pin           VARCHAR(4),
    cvv           VARCHAR(3),
    track1        VARCHAR(50),
    track2        VARCHAR(50),
    expiring_date VARCHAR(34)
);

CREATE TABLE IF NOT EXISTS company (
    company_id   VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(50),
    phone        VARCHAR(20),
    email        VARCHAR(50),
    country      VARCHAR(20),
    website      VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS transaction (
    id          VARCHAR(100) PRIMARY KEY,
    card_id     VARCHAR(10),
    business_id VARCHAR(10),
    timestamp   TIMESTAMP,
    amount      DECIMAL(10, 2),
    declined    BOOLEAN,
    product_ids VARCHAR(20),
    user_id     VARCHAR(5),
    lat         FLOAT,
    longitude   FLOAT,
    FOREIGN KEY (card_id)     REFERENCES credit_card(id),
    FOREIGN KEY (business_id) REFERENCES company(company_id),
    FOREIGN KEY (user_id)     REFERENCES user(id)
);


-- ── Carga de datos desde CSV ─────────────────────────────────
-- Usuarios distribuidos en 3 archivos por país (US, CA, UK)

SHOW VARIABLES LIKE 'secure_file_priv'; -- verificar ruta permitida para LOAD DATA

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_uk.csv"
INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_usa.csv"
INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_ca.csv"
INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\credit_cards.csv"
INTO TABLE credit_card
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\companies.csv"
INTO TABLE company
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Nota: transactions usa ';' como separador (distinto al resto de CSVs)
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\transactions.csv"
INTO TABLE transaction
FIELDS TERMINATED BY ';' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- ── Consultas analíticas ─────────────────────────────────────

-- Usuarios con más de 30 transacciones
SELECT
    u.id,
    CONCAT(u.name, ' ', u.surname) AS nombre_completo,
    (SELECT COUNT(t.id) FROM transaction t WHERE t.user_id = u.id) AS num_transacciones
FROM user u
GROUP BY u.id
HAVING num_transacciones > 30
ORDER BY num_transacciones DESC;

-- Importe medio por IBAN para transacciones de 'Donec Ltd'
SELECT cred.iban, ROUND(AVG(amount), 2) AS promedio_amount
FROM transaction t
JOIN company c     ON t.business_id = c.company_id
JOIN credit_card cred ON t.card_id  = cred.id
WHERE company_name = 'Donec Ltd'
GROUP BY cred.iban;


-- ── Estado de tarjetas (window functions) ────────────────────
-- Clasifica cada tarjeta como activa o inactiva según si sus
-- últimas 3 transacciones fueron declinadas

CREATE VIEW RankedTransactions AS (
    SELECT
        card_id,
        declined,
        ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS rn
    FROM transaction
);

CREATE VIEW CardStatus AS (
    SELECT
        card_id,
        CASE
            WHEN SUM(declined) >= 3 THEN 'inactive'
            ELSE 'active'
        END AS status
    FROM RankedTransactions
    WHERE rn <= 3
    GROUP BY card_id
);

-- Materializar la vista como tabla para consultas más eficientes
CREATE TABLE card_status AS (SELECT * FROM CardStatus);

-- Resumen: cuántas tarjetas están activas vs inactivas
SELECT status, COUNT(card_id) AS total
FROM CardStatus
GROUP BY status;
