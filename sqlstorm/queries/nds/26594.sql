
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY COUNT(DISTINCT ca_address_id) DESC) AS addr_rank
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    d.cd_gender,
    d.customer_count,
    d.total_dependents,
    d.average_purchase_estimate,
    s.total_sales,
    s.total_orders
FROM 
    address_summary a
JOIN 
    demographics_summary d ON d.customer_count > 100
JOIN 
    sales_summary s ON s.total_orders > 50
WHERE 
    a.addr_rank = 1
ORDER BY 
    a.unique_addresses DESC, d.customer_count DESC, s.total_sales DESC
LIMIT 100;
