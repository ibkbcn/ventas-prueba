# Revenue Analysis Dashboard

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=flat&logo=powerbi&logoColor=black)

Pipeline completo de análisis de ventas: desde la modelización relacional en MySQL hasta un dashboard interactivo en Power BI con KPIs de negocio y medidas DAX.

---

## Contexto del Proyecto

Dataset de transacciones financieras multi-país (EE.UU., Canadá, Reino Unido) con datos de empresas cliente, tarjetas de crédito, usuarios y productos. El objetivo era construir una base de datos analítica desde cero y habilitar el seguimiento de KPIs comerciales a través de un dashboard ejecutivo.

---

## Arquitectura

```
CSVs multi-país (US / CA / UK)
        │
        ▼
┌──────────────────┐
│  MySQL — Sprint  │  Modelado relacional, limpieza, FK constraints
│  2, 3 y 4        │  ALTER TABLE, STR_TO_DATE, LOAD DATA INFILE
└────────┬─────────┘
         │ Star Schema
         ▼
┌──────────────────┐
│  Power BI        │  Modelo estrella, DAX measures, KPIs
│  Sprint 5        │  3 niveles: overview, cartera, comportamiento usuario
└──────────────────┘
```

---

## Modelo de Datos — MySQL

El esquema fue construido de forma incremental a lo largo de 3 sprints:

| Tabla | Tipo | Descripción |
|---|---|---|
| `transaction` | Fact | Transacciones con importe, timestamp, estado declined |
| `company` | Dimensión | Empresas cliente por país |
| `user` | Dimensión | Usuarios finales (US, CA, UK) |
| `credit_card` | Dimensión | Tarjetas con IBAN, PIN, CVV, fecha expiración |
| `products` | Dimensión | Catálogo de productos con precio |
| `comprados` | Tabla intermedia | Desagrega transacciones por producto (N:M) |

### Decisiones técnicas destacadas

**Migración de tipos de fecha:** Los datos de `expiring_date` llegaban como string en formato `MM/DD/YY`. Se gestionó la conversión en dos pasos para evitar errores de integridad:
```sql
ALTER TABLE credit_card MODIFY COLUMN expiring_date VARCHAR(10);
UPDATE credit_card SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y');
ALTER TABLE credit_card MODIFY COLUMN expiring_date DATE;
```

**Carga multi-país con LOAD DATA INFILE:**

Los CSVs están disponibles en la carpeta [`/data`](./data) del repositorio.

```sql
LOAD DATA INFILE "users_usa.csv" INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
-- Repetido para users_uk.csv y users_ca.csv
```

**Análisis con subqueries y JOINs:**
```sql
-- Empresas con importe promedio superior a la media global
SELECT company_name FROM company
WHERE id IN (
    SELECT company_id FROM transaction
    WHERE amount > (SELECT AVG(amount) FROM transaction)
);

-- Top 5 días por volumen de ventas
SELECT DATE(timestamp), SUM(amount)
FROM transaction WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY SUM(amount) DESC LIMIT 5;
```

---

## Modelo en Power BI — Star Schema

La tabla `transaction` actúa como tabla de hechos central, conectada a `credit_card`, `company`, `user` y `products` a través de la tabla intermedia `comprados`. Esta arquitectura permite análisis por producto sin duplicar filas de transacción. El modelo incluye una tabla `Medidas` separada como buena práctica de organización DAX.

<p align="center">
  <img width="1689" height="1019" alt="image" src="https://github.com/user-attachments/assets/78664e70-9c69-4298-8309-541d69796424" />
</p>


### DAX Measures principales

```dax
-- KPI: Promedio por transacción con conversión multi-divisa
avg_transacción_€ = AVERAGE('transaction'[amount])
Promedio de transacción en Dólares = [avg_transacción_€] * 1.08

-- KPI: Operaciones declinadas por mes
Transacciones declinadas =
    CALCULATE(COUNTROWS('transaction'), 'transaction'[declined] = TRUE())

-- KPI: Empresas activas por país
Recuento compañías con transacciones =
    CALCULATE(DISTINCTCOUNT(company[company_name]), 'transaction'[id])

-- Estadística de usuario
std_ventas = STDEV.P('transaction'[amount])
prod_más_caro = CALCULATE(MAX(products[price]), RELATEDTABLE(comprados))
```

---

## Páginas del Dashboard

### Página 1 — Visión General (Cierre Q1 2022)
KPIs de facturación anual, ticket medio, empresas activas por país y evolución de operaciones declinadas.

<p align="center">
  <img width="1307" height="737" alt="Dashboard Overview" src="https://github.com/user-attachments/assets/7da6de7a-f2bf-45f0-b838-b9233e6b1160"/>
</p>

### Página 2 — Cartera de Clientes y Presencia de Mercado
Segmentación de usuarios finales, distribución geográfica y análisis de ingresos por país.

<p align="center">
  <img width="1303" height="733" alt="Dashboard Cartera" src="https://github.com/user-attachments/assets/0286c667-ba6f-4a73-9a35-ef12496cb7a2"/>
</p>

---

## Hallazgos Clave

- **Canadá representa el 52% de los ingresos** con solo el 40% de los usuarios — mayor ticket medio por cliente que EE.UU. y UK
- **La totalidad de las operaciones declinadas provienen de Canadá** (21.200€), señalando un riesgo de fraude geográficamente concentrado
- **Q1 2022 alcanzó 22.000€** acercándose al objetivo anual de 25.000€ en solo 3 meses
- **2021 cumplió el objetivo de ticket medio de 250€** (251€); en 2022 no se alcanzó (promedio 204€ en los meses disponibles)
- **Objetivo de operaciones declinadas (<10/mes)**: superado únicamente entre abril y junio de 2021

---

## Stack Tecnológico

| Herramienta | Uso |
|---|---|
| MySQL | Modelado relacional, ingesta de datos, consultas analíticas |
| SQL (JOINs, subqueries, GROUP BY, DATE functions) | Análisis y transformación de datos |
| Power BI | Visualización, star schema, KPIs |
| DAX (CALCULATE, AVERAGE, STDEV.P, RELATEDTABLE) | Medidas analíticas y condicionales |
| Power Query | ETL y conexión MySQL → Power BI |

---

## Scripts SQL

El modelado relacional completo se desarrolló en tres fases progresivas, disponibles en la carpeta [`/sql`](./sql):

| Archivo | Contenido |
|---|---|
| [`01_queries_company_transaction.sql`](./sql/01_queries_company_transaction.sql) | Consultas analíticas: JOINs, subqueries, GROUP BY, funciones de fecha |
| [`02_credit_card_schema.sql`](./sql/02_credit_card_schema.sql) | Integración de `credit_card`: ALTER TABLE, STR_TO_DATE, FK constraints |
| [`03_full_schema_load_data.sql`](./sql/03_full_schema_load_data.sql) | Schema completo con todas las tablas + LOAD DATA INFILE multi-país |
