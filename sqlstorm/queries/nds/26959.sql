
WITH address_details AS (
    SELECT 
        ca_city,
        ca_state,
        LOWER(ca_street_name) AS street_name_lower,
        UPPER(ca_street_type) AS street_type_upper,
        CONCAT(ca_street_number, ' ', LOWER(ca_street_name), ' ', UPPER(ca_street_type)) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
),
demo_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
date_summary AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT d_date_sk) AS total_days,
        MAX(d_dom) AS max_day_of_month,
        MIN(d_dom) AS min_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.street_name_lower,
    ad.street_type_upper,
    ad.full_address,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_customers,
    ds.total_dependents,
    ds.avg_purchase_estimate,
    dt.total_days,
    dt.max_day_of_month,
    dt.min_day_of_month
FROM 
    address_details ad
JOIN 
    demo_summary ds ON ad.addr_rank = 1
JOIN 
    date_summary dt ON dt.d_year = 2023
ORDER BY 
    ad.ca_city, ad.ca_state, ds.total_customers DESC;
