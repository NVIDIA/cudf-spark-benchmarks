
WITH  sales_chain AS (
    SELECT ss_store_sk, ss_item_sk, 
           SUM(ss_quantity) AS total_quantity, 
           SUM(ss_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_quantity) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY ss_store_sk, ss_item_sk
),
top_sales AS (
    SELECT ss_store_sk, total_quantity, total_sales
    FROM sales_chain
    WHERE sales_rank <= 5
),
missed_sales AS (
    SELECT ss_store_sk, COUNT(DISTINCT ss_item_sk) AS missed_items
    FROM store_sales
    WHERE ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss_store_sk
),
customer_analysis AS (
    SELECT c.c_customer_sk, 
           COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
           AVG(ws.ws_net_paid_inc_tax) AS avg_spent,
           MAX(cd.cd_purchase_estimate) AS max_estimate
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
purchase_trends AS (
    SELECT d.d_year, 
           SUM(ws.ws_net_paid_inc_tax) AS yearly_sales,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT t.yearly_sales, t.total_orders,
       COALESCE(ts.total_quantity, 0) AS top_sales_quantity,
       COALESCE(ms.missed_items, 0) AS missed_sales_count,
       ca.purchase_count, ca.avg_spent
FROM purchase_trends t
LEFT JOIN top_sales ts ON t.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN missed_sales ms ON ts.ss_store_sk = ms.ss_store_sk
LEFT JOIN customer_analysis ca ON ca.c_customer_sk = (SELECT MAX(c_customer_sk) FROM customer)
ORDER BY t.yearly_sales DESC;
