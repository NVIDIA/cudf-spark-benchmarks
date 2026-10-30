
WITH  SalesData AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451914  
    GROUP BY ws_item_sk
), 
CustomerStats AS (
    SELECT c.c_customer_sk, 
           cd.cd_gender, 
           SUM(s.ws_net_profit) AS total_profit,
           COUNT(DISTINCT s.ws_order_number) AS num_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
MergedSales AS (
    SELECT cs.c_customer_sk, 
           COALESCE(cs.total_profit, 0) AS total_profit,
           SUM(sd.total_sales) AS sales_from_web
    FROM CustomerStats cs
    RIGHT JOIN SalesData sd ON cs.c_customer_sk IS NULL
    GROUP BY cs.c_customer_sk, cs.total_profit
)
SELECT CASE 
           WHEN total_profit > 5000 THEN 'High Value'
           WHEN total_profit BETWEEN 1000 AND 5000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       AVG(s.sales_from_web) AS avg_web_sales,
       MAX(s.total_profit) AS max_profit,
       MIN(s.total_profit) AS min_profit,
       COUNT(s.c_customer_sk) AS num_customers
FROM MergedSales s
WHERE s.sales_from_web IS NOT NULL
GROUP BY customer_value
HAVING COUNT(DISTINCT s.c_customer_sk) > 10  
ORDER BY avg_web_sales DESC, max_profit ASC;
