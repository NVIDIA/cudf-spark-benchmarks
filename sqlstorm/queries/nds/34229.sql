
WITH  Sales_Rank AS (
    SELECT ws_order_number, 
           SUM(ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_order_number
),
Total_Profit AS (
    SELECT ws_item_sk,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
Customer_Statistics AS (
    SELECT c.c_customer_sk,
           MAX(d.d_year) AS last_purchase_year,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk
)
SELECT ca.ca_city, 
       COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
       SUM(tp.total_profit) AS total_profit,
       AVG(cs.total_spent) AS avg_spent,
       (SELECT COUNT(*) 
        FROM Sales_Rank sr 
        WHERE sr.sales_rank <= 10) AS top_sales
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN Customer_Statistics cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN Total_Profit tp ON tp.ws_item_sk IN (
    SELECT DISTINCT ws.ws_item_sk 
    FROM web_sales ws
    WHERE ws.ws_ship_customer_sk IS NOT NULL
)
WHERE ca.ca_country = 'USA' 
AND (cs.total_orders > 5 OR cs.last_purchase_year = 2023)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT cs.c_customer_sk) > 0
ORDER BY customer_count DESC;
