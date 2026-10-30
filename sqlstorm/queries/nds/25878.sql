
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_country AS country,
        ca.ca_zip AS zip,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
FormattedResults AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.full_name,
        c.gender,
        c.marital_status,
        c.city,
        c.state,
        c.country,
        c.zip,
        STRING_AGG(DISTINCT CAST(c.hd_income_band_sk AS STRING), ', ') AS income_bands,
        STRING_AGG(DISTINCT c.hd_buy_potential, ', ') AS buying_potentials
    FROM CustomerDetails c
    GROUP BY c.c_customer_id, c.full_name, c.gender, c.marital_status, c.city, c.state, c.country, c.zip
)
SELECT 
    fr.full_name,
    fr.gender,
    fr.marital_status,
    fr.city,
    fr.state,
    fr.country,
    fr.zip,
    COALESCE(fr.income_bands, 'No Income Data') AS income_bands,
    COALESCE(fr.buying_potentials, 'No Buying Potential Data') AS buying_potentials
FROM FormattedResults fr
ORDER BY fr.city, fr.full_name;
