
WITH NumericAddress AS (
    SELECT 
        ca_address_sk, 
        ca_street_number, 
        ca_street_name, 
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address,
        LENGTH(ca_street_number) + LENGTH(ca_street_name) AS total_length
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
GenderIncome AS (
    SELECT 
        cd_gender, 
        ib_lower_bound, 
        ib_upper_bound,
        COUNT(*) AS demographic_count
    FROM customer_demographics 
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY cd_gender, ib_lower_bound, ib_upper_bound
),
DateInfo AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(*) AS total_days,
        SUM(d_dom) AS total_days_in_month
    FROM date_dim
    GROUP BY d_year, d_month_seq
),
OptimizedString AS (
    SELECT 
        ca_address_sk, 
        UPPER(SUBSTRING(full_address, 1, 10)) AS truncated_upper_address,
        REPLACE(full_address, ' ', '-') AS dashed_address
    FROM NumericAddress 
)
SELECT 
    gi.cd_gender, 
    gi.ib_lower_bound, 
    gi.ib_upper_bound, 
    di.d_year, 
    di.total_days, 
    si.truncated_upper_address,
    si.dashed_address,
    SUM(gi.demographic_count) AS total_customers
FROM GenderIncome gi
JOIN DateInfo di ON di.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
JOIN OptimizedString si ON si.ca_address_sk IN (1, 2, 3) 
GROUP BY 
    gi.cd_gender, 
    gi.ib_lower_bound, 
    gi.ib_upper_bound, 
    di.d_year, 
    di.total_days, 
    si.truncated_upper_address,
    si.dashed_address
ORDER BY 
    gi.cd_gender ASC, 
    gi.ib_lower_bound ASC;
