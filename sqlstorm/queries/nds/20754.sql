
WITH  item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
    GROUP BY c.c_customer_sk, ca.ca_state, cd.cd_marital_status, cd.cd_gender
), 
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.ca_state,
        ci.cd_marital_status,
        ci.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_net_profit > 0
    GROUP BY ci.c_customer_sk, ci.ca_state, ci.cd_marital_status, ci.cd_gender
)
SELECT 
    hvc.ca_state,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count,
    AVG(hvc.total_net_profit) AS average_net_profit,
    (SELECT 
         SUM(total_quantity) 
     FROM item_sales 
     WHERE sales_rank <= 5 
     AND ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_ship_date_sk > 20200101)
    ) AS total_sales_for_top_items
FROM high_value_customers hvc
GROUP BY hvc.ca_state, hvc.cd_gender, hvc.cd_marital_status
HAVING AVG(hvc.total_net_profit) > (SELECT AVG(total_net_profit) FROM high_value_customers) 
   AND COUNT(DISTINCT hvc.c_customer_sk) > 10 
ORDER BY high_value_customer_count DESC 
LIMIT 10;
