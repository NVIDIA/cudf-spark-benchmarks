WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        ROUND(AVG(LENGTH(ca_street_name)), 2) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        ROUND(AVG(cd_purchase_estimate), 2) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_marital_status
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS unique_dates,
        COUNT(*) AS total_dates,
        MAX(d_dom) AS max_day_of_month,
        MIN(d_dom) AS min_day_of_month,
        ROUND(AVG(d_dom), 2) AS avg_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    a.max_street_name_length,
    a.min_street_name_length,
    a.avg_street_name_length,
    c.cd_marital_status,
    c.customer_count,
    c.total_dependents,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    c.avg_purchase_estimate,
    d.d_year,
    d.unique_dates,
    d.total_dates,
    d.max_day_of_month,
    d.min_day_of_month,
    d.avg_day_of_month
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.unique_addresses > 1000
JOIN 
    DateStats d ON EXTRACT(YEAR FROM cast('2002-10-01' as date)) - d.d_year <= 5
ORDER BY 
    a.ca_state, c.cd_marital_status;