
WITH  sales_data AS (
    SELECT s.ss_sold_date_sk, s.ss_item_sk, s.ss_quantity, 
           s.ss_net_paid, s.ss_ext_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_sold_date_sk) as sales_rank
    FROM store_sales s
    WHERE s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021)
),
customer_spending AS (
    SELECT c.c_customer_sk, SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT cs.c_customer_sk, cs.total_spent,
           DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM customer_spending cs
),
recent_sales AS (
    SELECT sd.ss_sold_date_sk, sd.ss_item_sk, sd.ss_quantity,
           sd.ss_net_paid, sd.ss_ext_sales_price
    FROM sales_data sd
    WHERE sd.sales_rank <= 10
)
SELECT tc.c_customer_sk, tc.total_spent, 
       COUNT(rs.ss_item_sk) AS items_purchased,
       COALESCE(SUM(rs.ss_net_paid), 0) AS total_sales,
       STRING_AGG(DISTINCT i.i_item_id, ', ') AS purchased_items
FROM top_customers tc
LEFT JOIN recent_sales rs ON rs.ss_item_sk IN (
    SELECT ss_item_sk 
    FROM store_sales 
    WHERE ss_sold_date_sk IN (
        SELECT DISTINCT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2021 AND d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_dow = 5)
    )
)
LEFT JOIN item i ON rs.ss_item_sk = i.i_item_sk
WHERE tc.rank <= 100
GROUP BY tc.c_customer_sk, tc.total_spent
HAVING COALESCE(SUM(rs.ss_net_paid), 0) > 1000
ORDER BY tc.total_spent DESC;
