
WITH  Sales_CTE AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_ship_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_ship_date_sk, cs_item_sk
    HAVING SUM(cs_net_profit) > 1000
),
Ranked_Sales AS (
    SELECT
        sales.ws_ship_date_sk,
        sales.ws_item_sk,
        sales.total_quantity,
        sales.total_profit,
        RANK() OVER (PARTITION BY sales.ws_ship_date_sk ORDER BY sales.total_profit DESC) as sales_rank
    FROM Sales_CTE sales
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    SUM(cs.total_web_orders) AS total_web_orders,
    SUM(cs.total_catalog_orders) AS total_catalog_orders,
    AVG(rs.total_profit) AS avg_profit
FROM customer_address ca
INNER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN Customer_Sales cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN Ranked_Sales rs ON c.c_customer_sk = rs.ws_item_sk
WHERE cd.cd_marital_status = 'M' 
AND cd.cd_purchase_estimate IS NOT NULL
AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
GROUP BY ca.ca_city, ca.ca_state, cd.cd_gender
HAVING SUM(cs.total_web_orders) > 10
    OR SUM(cs.total_catalog_orders) > 5
ORDER BY avg_profit DESC;
