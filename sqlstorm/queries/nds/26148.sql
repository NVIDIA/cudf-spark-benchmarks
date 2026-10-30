
WITH Address_City AS (
    SELECT DISTINCT ca_city
    FROM customer_address
    WHERE ca_city IS NOT NULL
), Customer_Full_Names AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_customer_sk
    FROM customer c
), City_Customer_Count AS (
    SELECT 
        ac.ca_city,
        COUNT(DISTINCT cfn.c_customer_sk) AS customer_count
    FROM Address_City ac
    LEFT JOIN Customer_Full_Names cfn ON cfn.c_customer_sk IN (
        SELECT c_current_addr_sk
        FROM customer
    )
    GROUP BY ac.ca_city
), Avg_Income_Band AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(hd.hd_dep_count) AS avg_dep_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ccc.ca_city, 
    ccc.customer_count, 
    aib.avg_dep_count,
    ccc.customer_count * aib.avg_dep_count AS benchmark_value
FROM City_Customer_Count ccc
JOIN Avg_Income_Band aib ON ccc.ca_city IS NOT NULL
ORDER BY benchmark_value DESC
LIMIT 10;
