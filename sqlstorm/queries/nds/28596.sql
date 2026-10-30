
WITH address_stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN ca_state = 'NY' THEN 1 ELSE 0 END) AS ny_addresses,
        SUM(CASE WHEN SUBSTRING(ca_street_name, 1, 5) = 'Main ' THEN 1 ELSE 0 END) AS main_street_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
demographic_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_stats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        COUNT(DISTINCT d_month_seq) AS unique_months,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_count
    FROM 
        date_dim
    GROUP BY 
        d_year
),
combined_stats AS (
    SELECT 
        a.ca_city,
        a.total_addresses,
        a.ny_addresses,
        a.main_street_addresses,
        d.cd_gender,
        d.total_customers,
        d.avg_purchase_estimate,
        d.married_count,
        dt.d_year,
        dt.total_dates,
        dt.unique_months,
        dt.holiday_count
    FROM 
        address_stats a
    JOIN 
        demographic_stats d ON a.total_addresses > 100
    JOIN 
        date_stats dt ON dt.total_dates > 10
)
SELECT 
    ca_city,
    cd_gender,
    d_year,
    total_addresses,
    ny_addresses,
    main_street_addresses,
    total_customers,
    avg_purchase_estimate,
    married_count,
    total_dates,
    unique_months,
    holiday_count
FROM 
    combined_stats
ORDER BY 
    ca_city, cd_gender, d_year;
