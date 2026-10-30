
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id, i_category, 0 AS lvl
    FROM item
    WHERE i_category IS NOT NULL
    UNION ALL
    SELECT sub.i_category_id, CONCAT('Subcategory of ', cat.i_category), cat.lvl + 1
    FROM item AS sub
    JOIN CategoryHierarchy AS cat ON sub.i_category_id = cat.i_category_id 
    WHERE cat.lvl < 2
),
CustomerActivity AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_net_profit) AS avg_profit
    FROM customer c
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT ca.c_customer_sk,
           ca.c_first_name,
           ca.c_last_name,
           ca.total_orders,
           ca.total_sales,
           ca.avg_profit,
           ROW_NUMBER() OVER (PARTITION BY ca.c_customer_sk ORDER BY ca.total_sales DESC) AS sales_rank
    FROM CustomerActivity ca
    WHERE ca.total_sales IS NOT NULL AND ca.total_orders > 5
),
HighValueCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_high_value_sales
    FROM customer c
    INNER JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ext_sales_price > 100
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT f.c_first_name,
       f.c_last_name,
       f.total_orders,
       f.total_sales,
       f.avg_profit,
       COALESCE(h.total_high_value_sales, 0) AS total_high_value_sales,
       CASE 
           WHEN f.total_sales > 10000 THEN 'VIP'
           WHEN f.avg_profit > 500 THEN 'Valued Customer'
           ELSE 'Regular Customer'
       END AS customer_type,
       ch.i_category
FROM FilteredSales f
LEFT JOIN HighValueCustomers h ON f.c_customer_sk = h.c_customer_sk
CROSS JOIN (SELECT DISTINCT i_category FROM item) AS ch
WHERE f.sales_rank <= 50
ORDER BY f.total_sales DESC
LIMIT 100;
