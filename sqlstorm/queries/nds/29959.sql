
WITH address_summary AS (
    SELECT 
        ca_state,
        CONCAT(ca_city, ', ', ca_street_name) AS full_address,
        COUNT(DISTINCT ca_address_id) AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city, ca_street_name
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
item_summary AS (
    SELECT 
        i_category,
        COUNT(i_item_id) AS total_items,
        AVG(i_current_price) AS avg_price
    FROM 
        item
    GROUP BY 
        i_category
),
sales_summary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        web_sales
    FULL OUTER JOIN 
        catalog_sales ON ws_order_number = cs_order_number
    FULL OUTER JOIN 
        store_sales ON ws_order_number = ss_ticket_number
)
SELECT 
    a.ca_state,
    a.full_address,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    i.i_category,
    i.total_items,
    i.avg_price,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales
FROM 
    address_summary a
JOIN 
    customer_summary c ON c.total_customers > 100
JOIN 
    item_summary i ON i.total_items > 10
CROSS JOIN 
    sales_summary s
ORDER BY 
    a.ca_state, i.i_category;
