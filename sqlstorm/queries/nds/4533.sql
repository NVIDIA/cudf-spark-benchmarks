WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451916 
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    SUM(COALESCE(r.total_sales, 0)) AS total_web_sales
FROM 
    customer_address a
LEFT JOIN 
    catalog_sales cs ON a.ca_address_sk = cs.cs_ship_addr_sk
LEFT JOIN 
    ranked_sales r ON cs.cs_item_sk = r.ws_item_sk AND r.sales_rank = 1
JOIN 
    customer_stats cust ON cust.total_orders > 5
WHERE 
    a.ca_state IN ('CA', 'NY') 
    AND ((a.ca_city LIKE '%Los Angeles%' OR a.ca_city LIKE '%New York%') OR a.ca_zip IS NULL)
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    COUNT(cs.cs_order_number) > 10 
ORDER BY 
    total_web_sales DESC;