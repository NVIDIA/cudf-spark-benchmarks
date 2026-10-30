
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_street_names,
        COUNT(DISTINCT ca_street_type) AS unique_street_types,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type = 'Avenue' THEN 1 ELSE 0 END) AS avenue_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
)
SELECT 
    addr.ca_city,
    addr.unique_addresses,
    addr.unique_street_names,
    addr.avg_street_name_length,
    demo.cd_gender,
    demo.demo_count,
    demo.avg_purchase_estimate,
    sales.total_sales_price,
    sales.total_quantity
FROM 
    address_summary addr
JOIN 
    demographic_summary demo ON demo.demo_count > 100
JOIN 
    sales_summary sales ON sales.total_quantity > 50
ORDER BY 
    addr.unique_addresses DESC, 
    demo.avg_purchase_estimate DESC;
