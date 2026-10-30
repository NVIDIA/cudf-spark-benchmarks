
WITH CustomerCityCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city
),
CityIncomeBands AS (
    SELECT 
        cac.ca_city,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Not Specified'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band
    FROM 
        CustomerCityCounts cac
    JOIN 
        household_demographics hd ON hd.hd_demo_sk IN (
            SELECT c.c_current_cdemo_sk
            FROM customer c
        )
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
CityIncomeStats AS (
    SELECT 
        ca_city,
        income_band,
        COUNT(*) AS income_band_count,
        AVG(COUNT(*)) OVER (PARTITION BY ca_city) AS avg_income_band_count
    FROM 
        CityIncomeBands
    GROUP BY 
        ca_city, income_band
)
SELECT 
    c.city,
    c.average_customers,
    ci.income_band,
    ci.income_band_count,
    ci.avg_income_band_count
FROM 
    (SELECT 
         ca_city AS city,
         AVG(customer_count) AS average_customers
     FROM 
         CustomerCityCounts 
     GROUP BY 
         ca_city) c
JOIN 
    CityIncomeStats ci ON c.city = ci.ca_city
ORDER BY 
    c.average_customers DESC, ci.income_band_count DESC;
