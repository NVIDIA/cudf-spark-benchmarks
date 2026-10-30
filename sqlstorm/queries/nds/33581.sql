
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss_net_profit) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    ca.ca_city,
    SUM(ss.total_quantity) AS total_quantity_sold,
    ROUND(AVG(ss.total_profit), 2) AS avg_profit_per_sale,
    COUNT(DISTINCT cr.cr_order_number) AS total_returned_orders,
    COUNT(DISTINCT cr.cr_item_sk) AS total_distinct_returned_items
FROM customer_address ca
LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
LEFT JOIN store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
JOIN sales_summary ss ON ws.ws_sold_date_sk = ss.ws_sold_date_sk
JOIN customer_ranking crk ON ws.ws_bill_customer_sk = crk.c_customer_sk
WHERE ca.ca_state = 'CA' 
    AND ss.rank <= 5 
    AND crk.gender_rank <= 10
    AND ws.ws_ship_mode_sk IS NOT NULL
GROUP BY ca.ca_city
ORDER BY total_quantity_sold DESC
LIMIT 10;
