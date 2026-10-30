
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type LIKE '%Ave%' THEN 1 ELSE 0 END) AS ave_street_count,
        SUM(CASE WHEN ca_street_type LIKE '%St%' THEN 1 ELSE 0 END) AS st_street_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics_Analysis AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Analysis AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sales_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        CAST(d.d_date AS DATE)
)
SELECT 
    a.ca_city,
    a.unique_addresses,
    a.avg_street_name_length,
    a.ave_street_count,
    a.st_street_count,
    d.cd_gender,
    d.total_customers,
    d.avg_purchase_estimate,
    d.total_dependencies,
    s.sales_date,
    s.total_sales,
    s.total_orders,
    s.total_quantity
FROM 
    Address_Analysis a
JOIN 
    Demographics_Analysis d ON a.unique_addresses > 0
JOIN 
    Sales_Analysis s ON a.unique_addresses > 100
WHERE 
    s.total_sales > 10000
ORDER BY 
    a.unique_addresses DESC, s.total_sales DESC;
