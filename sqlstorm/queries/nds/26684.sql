
WITH processed_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        LENGTH(ca_country) AS country_length,
        UPPER(ca_country) AS upper_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY', 'TX') 
        AND ca_city IS NOT NULL
),
customer_stats AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
date_stats AS (
    SELECT 
        d_year,
        COUNT(d_date) AS total_days,
        SUM(d_dom) AS total_days_in_month
    FROM 
        date_dim
    GROUP BY 
        d_year
),
final_benchmark AS (
    SELECT 
        pd.full_address,
        cs.customer_count,
        cs.avg_purchase_estimate,
        ds.total_days,
        ds.total_days_in_month,
        pd.upper_country
    FROM 
        processed_data pd
    JOIN 
        customer_stats cs ON pd.ca_address_sk = cs.cd_demo_sk
    JOIN 
        date_stats ds ON EXTRACT(YEAR FROM CURRENT_DATE) = ds.d_year
)
SELECT 
    full_address,
    customer_count,
    avg_purchase_estimate,
    total_days,
    total_days_in_month,
    upper_country
FROM 
    final_benchmark
ORDER BY 
    customer_count DESC, 
    avg_purchase_estimate DESC;
