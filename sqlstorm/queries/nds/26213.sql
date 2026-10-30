
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', TRIM(ca_suite_number))
                   ELSE ''
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), address_metrics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(full_address)) AS avg_address_length
    FROM 
        processed_addresses
    GROUP BY 
        ca_state
), demo_metrics AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
), sales_metrics AS (
    SELECT 
        EXTRACT(YEAR FROM d_date) AS sales_year,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d_date)
)
SELECT 
    am.ca_state, 
    am.address_count, 
    am.avg_address_length, 
    dm.cd_gender, 
    dm.customer_count, 
    dm.avg_purchase_estimate,
    sm.sales_year, 
    sm.total_sales, 
    sm.total_quantity_sold
FROM 
    address_metrics am
JOIN 
    demo_metrics dm ON dm.customer_count > 100
JOIN 
    sales_metrics sm ON sm.total_sales > 10000
ORDER BY 
    am.ca_state, dm.cd_gender, sm.sales_year;
