CREATE DATABASE Sprint3;
USE Sprint3;

#Nivell 1

#Ejercicio 1

CREATE TABLE IF NOT EXISTS credit_card(
		id VARCHAR(15) PRIMARY KEY,
        iban VARCHAR(100),
        pan  VARCHAR(50),
        pin  INT, #(10)
        cvv  INT, #(10)
        expiring_date DATE
	);
    
# 1.Transformo a VARCHAR para editar la fecha para que sea compatible
ALTER TABLE credit_card MODIFY COLUMN expiring_date varchar(10);

# AHora puedo insertar los datos dentro de la tabla credit_card !!!!!!!!

#Y despues de haber ingresado los datos uso STR_to_DATE para que se convierta en un formato correcto de fecha.

SET SQL_SAFE_UPDATES = 0;
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y');  # aqui le dije el formato de fecha que tenia mi string para que lo adaptara con el metodo STR_TO_DATE
SET SQL_SAFE_UPDATES = 1;

#2.Despues tengo que devolverlo a DATE format
SELECT expiring_date FROM credit_card; # comprobacion de que las fechas eestan en el formato correcto para convertirse en DATE
ALTER TABLE credit_card MODIFY COLUMN expiring_date DATE; # Conversion en DATE


#3.Conecto la foreign key de transaction a la primary key de credit_card

ALTER TABLE transaction ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id); # Funciona segun lo previsto eso si importante tener tablas transaction  y credit card bien    

#SET FOREIGN_KEY_CHECKS = 0; # Descativa todas las relaciones de FOREIGN KEY (facilita insercion de datos)
#SET FOREIGN_KEY_CHECKS = 1; # Activar FOREIGN KEY

# Ejercicio 2
#El departament de Recursos Humans ha identificat un error en el número de compte de l'usuari amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre és: R323456312213576817699999. Recorda mostrar que el canvi es va realitzar.

UPDATE credit_card
SET iban = 'R323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';


#Ejercicio 3

# Solucion INSERT INTO primero en las tablas de dimensiones para luego insertar en transaction.
INSERT INTO credit_card(id) VALUES ('CcU-9999'); #Worked

INSERT INTO company(id) VALUES('b-9999');  			#worked

#importante paso crear tabla user (cargar estructura + cargar datos a insertar en user) porque sino user_id en transaction me da error al no referenciar a ninguna tabla primaria de otra tabla
SET foreign_key_checks = 0; 			# se que no es best practice pero no se que mejor solucion darle

INSERT INTO user(id) VALUES('9999');  #worked when user has already been charge

SET foreign_key_checks = 1;

# Para finalizar agregar nueva información en transaction table 

INSERT INTO transaction(id,credit_card_id,company_id,user_id,lat,longitude,amount,declined) VALUES (  '108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999',  '9999', '829.999',  '-117.999', '111.11', '0') ;
#omite la columna timestamp

# testeo
SELECT * FROM transaction WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD' #funciona

#Ejercicio 4
ALTER TABLE credit_card 
DROP COLUMN pan;


#Nivell 2
#Ejercicio 1

#Paso1 Eliminar Foreign key from user para eliminar la FOREIGN KEY de una tabla de dimensiones!!!!
#Paso2 Crear la foreign key en transaction para conectar con user!!!
SELECT CONSTRAINT_NAME 
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_NAME = 'user' 
AND COLUMN_NAME = 'id' 
AND REFERENCED_TABLE_NAME = 'transaction' 
AND REFERENCED_COLUMN_NAME = 'user_id';

ALTER TABLE user DROP FOREIGN KEY user_ibfk_1;

ALTER TABLE transaction ADD FOREIGN KEY transaction (user_id) REFERENCES user(id);

#Elimina de la taula transaction el registre amb ID 02C6201E-D90A-1859-B4EE-88D2986D3B02 de la base de dades.

DELETE FROM transaction
WHERE id = '02C6201E-D90A-1859-B4EE-88D2986D3B02'; # ejecución

SELECT * FROM transaction
WHERE id = '02C6201E-D90A-1859-B4EE-88D2986D3B02'; # verificación

#Ejercicio 2
# Vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. 
#Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

CREATE VIEW VistaMarketing AS 
SELECT company_name, phone, country, AVG(amount) AS promedio_compras
FROM company c
JOIN transaction t
ON c.id = t.company_id
GROUP BY company_name,phone,country
ORDER BY promedio_compras DESC;


#Ejercicio 3
SELECT company_name FROM VistaMarketing WHERE country = 'Germany';


#Ejercicio 1

ALTER TABLE company DROP COLUMN website;
RENAME TABLE user TO data_user;

#Ejercicio 2 

CREATE VIEW InformeTecnico AS
SELECT t.id, u.name, u.surname, cre.iban, c.company_name
FROM transaction t 
JOIN company c ON t.company_id = c.id 
JOIN credit_card cre ON t.credit_card_id = cre.id
JOIN data_user u ON t.user_id = u.id;

SELECT * FROM informetecnico;



