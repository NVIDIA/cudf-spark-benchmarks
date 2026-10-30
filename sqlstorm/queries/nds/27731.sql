
WITH address_data AS (
    SELECT 
        CONCAT(ca_city, ', ', ca_state) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
demographic_data AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_data AS (
    SELECT 
        t.d_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    JOIN 
        date_dim t ON ws_sold_date_sk = t.d_date_sk 
    WHERE 
        t.d_year = 2023
    GROUP BY 
        t.d_date
)
SELECT 
    ad.full_address,
    dm.cd_gender,
    dm.avg_purchase_estimate,
    sd.d_date,
    sd.total_sales,
    sd.total_orders
FROM 
    address_data ad
JOIN 
    demographic_data dm ON ad.address_count > 10
JOIN 
    sales_data sd ON sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 50;
