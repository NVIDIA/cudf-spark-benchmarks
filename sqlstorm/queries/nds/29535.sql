
WITH customer_order_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_items_ordered,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales_value,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, full_name, ca.ca_city
),
demographic_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(cs.cs_net_profit) AS average_catalog_profit,
        AVG(ws.ws_net_profit) AS average_web_profit
    FROM 
        customer_demographics AS cd
    LEFT JOIN catalog_sales AS cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN web_sales AS ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cos.full_name,
    cos.ca_city,
    cos.total_items_ordered,
    cos.total_sales_value,
    ds.catalog_orders,
    ds.web_orders,
    ds.average_catalog_profit,
    ds.average_web_profit
FROM 
    customer_order_summary AS cos
LEFT JOIN demographic_summary AS ds ON cos.c_customer_sk = ds.cd_demo_sk
ORDER BY 
    cos.total_sales_value DESC
LIMIT 100;
