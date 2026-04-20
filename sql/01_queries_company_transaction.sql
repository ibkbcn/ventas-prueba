-- ============================================================
-- Revenue Analysis — Consultas Analíticas
-- company + transaction
-- ============================================================
-- Exploración y análisis de transacciones por empresa y país.
-- Requiere tablas: company, transaction (con datos cargados).
-- ============================================================


-- ── Presencia geográfica ─────────────────────────────────────

-- Países distintos donde operan las empresas cliente
SELECT DISTINCT country
FROM company
JOIN transaction ON company.id = transaction.company_id;

-- Total de países únicos con actividad transaccional
SELECT COUNT(DISTINCT country)
FROM company
JOIN transaction ON company.id = transaction.company_id;


-- ── Ranking de empresas ──────────────────────────────────────

-- Empresa con mayor importe medio por transacción (excl. declinadas)
SELECT company_name, AVG(amount) AS avg_amount
FROM company
JOIN transaction ON company.id = transaction.company_id
WHERE transaction.declined = 0
GROUP BY company_name
ORDER BY avg_amount DESC
LIMIT 1;

-- Empresas cuyo importe medio supera la media global
SELECT company_name
FROM company
WHERE id IN (
    SELECT company_id
    FROM transaction
    WHERE amount > (SELECT AVG(amount) FROM transaction)
);

-- Verificación: empresas sin ninguna transacción registrada
SELECT c.company_name
FROM company c
WHERE c.id NOT IN (
    SELECT t.company_id FROM transaction t
);


-- ── Análisis temporal ────────────────────────────────────────

-- Top 5 días por volumen de ventas
-- DATE() extrae la fecha de la columna timestamp (datetime)
SELECT DATE(timestamp) AS fecha, SUM(amount) AS total_ventas
FROM transaction
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY total_ventas DESC
LIMIT 5;

-- Importe medio por país de empresa, ordenado de mayor a menor
SELECT company.country, AVG(amount) AS avg_amount
FROM company
JOIN transaction ON company.id = transaction.company_id
WHERE declined = 0
GROUP BY company.country
ORDER BY avg_amount DESC;


-- ── Análisis de red de empresas ──────────────────────────────

-- Transacciones de empresas que comparten país con 'Non Institute'
-- Versión con JOIN
SELECT t.id
FROM transaction t
WHERE t.company_id IN (
    SELECT c1.id
    FROM company c1
    JOIN company c2 ON c1.country = c2.country
    WHERE c2.company_name = 'Non Institute'
);

-- Misma consulta usando solo subqueries anidadas (sin JOIN)
SELECT id
FROM transaction
WHERE company_id IN (
    SELECT id FROM company
    WHERE country = (
        SELECT country FROM company
        WHERE company_name = 'Non Institute'
    )
);


-- ── Filtros combinados ───────────────────────────────────────

-- Transacciones entre 100€ y 200€ en fechas clave de análisis
SELECT c.company_name, c.phone, c.country, DATE(t.timestamp), t.amount
FROM company c
JOIN transaction t ON c.id = t.company_id
WHERE t.amount BETWEEN 100 AND 200
  AND DATE(t.timestamp) IN ('2021-04-29', '2021-07-20', '2022-03-13')
ORDER BY t.amount DESC;

-- Clasificación de empresas por volumen de transacciones
SELECT
    c.company_name,
    COUNT(t.id) AS total_transacciones,
    CASE
        WHEN COUNT(t.id) > 4 THEN 'Alto volumen (> 4)'
        ELSE 'Bajo volumen (≤ 4)'
    END AS clasificacion
FROM company c
JOIN transaction t ON c.id = t.company_id
GROUP BY c.company_name;
