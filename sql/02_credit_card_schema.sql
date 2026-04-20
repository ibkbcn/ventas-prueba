-- Revenue Analysis — Integración de Credit Card
-- Añade la tabla credit_card al modelo relacional y la conecta
-- con transaction mediante FK. Incluye migración de tipos de fecha.

CREATE DATABASE IF NOT EXISTS Sprint3;
USE Sprint3;


-- Creación de la tabla credit_card

CREATE TABLE IF NOT EXISTS credit_card (
    id            VARCHAR(15) PRIMARY KEY,
    iban          VARCHAR(100),
    pan           VARCHAR(50),
    pin           INT,
    cvv           INT,
    expiring_date DATE
);


-- Migración de tipo de fecha
-- Los datos llegan con expiring_date como string (MM/DD/YY).
-- Se convierte en dos pasos para evitar errores de integridad.

-- Paso 1: convertir a VARCHAR para poder aplicar STR_TO_DATE
ALTER TABLE credit_card MODIFY COLUMN expiring_date VARCHAR(10);

-- (aquí se insertan los datos desde CSV)

-- Paso 2: convertir el string al formato DATE correcto
SET SQL_SAFE_UPDATES = 0;
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y');
SET SQL_SAFE_UPDATES = 1;

-- Paso 3: cambiar el tipo de columna definitivamente a DATE
ALTER TABLE credit_card MODIFY COLUMN expiring_date DATE;


-- FK: conectar credit_card con transaction
ALTER TABLE transaction
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);


-- Corrección de IBAN incorrecto detectado en auditoría de datos
UPDATE credit_card
SET iban = 'R323456312213576817699999'
WHERE id = 'CcU-2938';

-- Verificación del cambio
SELECT iban FROM credit_card WHERE id = 'CcU-2938';


-- Inserción de registro de prueba
-- Se insertan primero en las dimensiones para respetar FK

INSERT INTO credit_card(id) VALUES ('CcU-9999');
INSERT INTO company(id)     VALUES ('b-9999');

-- FK desactivada temporalmente para insertar en user sin dependencias
SET foreign_key_checks = 0;
INSERT INTO user(id) VALUES ('9999');
SET foreign_key_checks = 1;

-- Inserción en tabla de hechos
INSERT INTO transaction
    (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES
    ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', '111.11', '0');

-- Verificación
SELECT * FROM transaction WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


-- Eliminar columna PAN (datos sensibles de tarjeta, no necesarios para análisis)
ALTER TABLE credit_card DROP COLUMN pan;

-- Reasignar FK de user hacia transaction (corrección de dirección de relación)
ALTER TABLE user DROP FOREIGN KEY user_ibfk_1;
ALTER TABLE transaction ADD FOREIGN KEY (user_id) REFERENCES user(id);

-- Eliminar transacción con ID inválido detectado en limpieza
DELETE FROM transaction WHERE id = '02C6201E-D90A-1859-B4EE-88D2986D3B02';
SELECT * FROM transaction WHERE id = '02C6201E-D90A-1859-B4EE-88D2986D3B02'; -- debe devolver 0 filas


-- Vista para marketing: importe medio por empresa ordenado de mayor a menor
CREATE VIEW VistaMarketing AS
SELECT company_name, phone, country, AVG(amount) AS promedio_compras
FROM company c
JOIN transaction t ON c.id = t.company_id
GROUP BY company_name, phone, country
ORDER BY promedio_compras DESC;

-- Vista técnica: detalle de transacción con datos de usuario, tarjeta y empresa
CREATE VIEW InformeTecnico AS
SELECT t.id, u.name, u.surname, cre.iban, c.company_name
FROM transaction t
JOIN company c        ON t.company_id    = c.id
JOIN credit_card cre  ON t.credit_card_id = cre.id
JOIN data_user u      ON t.user_id        = u.id;


-- Ajustes finales de esquema
ALTER TABLE company DROP COLUMN website;
RENAME TABLE user TO data_user;
