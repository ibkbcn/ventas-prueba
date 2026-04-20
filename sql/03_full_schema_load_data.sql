CREATE DATABASE sprint4;
USE sprint4;   								

CREATE TABLE IF NOT EXISTS user (
    id VARCHAR(5) PRIMARY KEY, 
    name VARCHAR(10),
	surname VARCHAR(15),
    phone VARCHAR(20),
    email VARCHAR(50),
    birth_date VARCHAR(20),         			
    country VARCHAR(20),             
    city VARCHAR(30),
    postal_code VARCHAR(15),
    address VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS credit_card (          
    id VARCHAR(10) PRIMARY KEY,
    user_id VARCHAR(5),
	iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(4), 
    cvv VARCHAR(3),           
    track1 VARCHAR(50),             				 
    track2 VARCHAR(50),
    expiring_date VARCHAR(34)               		
);


CREATE TABLE IF NOT EXISTS company (           
    company_id VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(50),
	phone VARCHAR(20),
    email VARCHAR(50),
    country VARCHAR(20),                  
    website VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS transaction (         
    id VARCHAR(100) PRIMARY KEY, 
    card_id VARCHAR(10),
    business_id VARCHAR(10),
    timestamp TIMESTAMP,
    amount DECIMAL (10, 2),
    declined BOOLEAN,
    product_ids VARCHAR(20),
    user_id VARCHAR(5),
    lat FLOAT,
    longitude FLOAT,
    FOREIGN KEY (card_id) REFERENCES credit_card(id),
    FOREIGN KEY (business_id) REFERENCES company(company_id),
	FOREIGN KEY (user_id) REFERENCES user(id)
    );
    
SHOW VARIABLES LIKE 'secure_file_priv';

# Importar datos user
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_uk.csv"
INTO TABLE user
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' #worked
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_usa.csv"
INTO TABLE user
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\users_ca.csv"
INTO TABLE user
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

# Importar datos credit_card
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\credit_cards.csv"
INTO TABLE credit_card
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;	

#Importar datos company
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\companies.csv"
INTO TABLE company
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;		

#Importar datos transaction
LOAD DATA
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.0\\Uploads\\transactions.csv"
INTO TABLE transaction 
FIELDS TERMINATED BY ";"                                                         
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;		                    

# Ejercició 1 
#Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.

SELECT u.id, CONCAT(u.name, ' ', u.surname) AS full_name, 
(SELECT count(t.id) FROM transaction t WHERE t.user_id = u.id) AS num_transaction
FROM user u
GROUP BY u.id
HAVING num_transaction > 30
ORDER BY num_transaction DESC;

# Ejercició 2 
#Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.

SELECT cred.iban, ROUND(AVG(amount),2) AS promedio_amount
FROM transaction t
JOIN company c ON t.business_id = c.company_id
JOIN  credit_card cred ON t.card_id = cred.id
WHERE company_name = 'Donec Ltd'
GROUP BY cred.iban; 

#Nivell 2
#Ejercicio 1
# Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades i genera la següent consulta:
#Quantes targetes estan actives?

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
    WHERE rn = 3
    GROUP BY card_id
);

CREATE TABLE card_status AS ( SELECT * FROM CardStatus);

SELECT status, count(card_id)
FROM CardStatus
GROUP BY status;

