
WITH  recent_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY c_first_shipto_date_sk DESC) AS rn
    FROM customer
    WHERE c_birth_year IS NOT NULL
),
customer_with_return_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(sr.sr_return_quantity) AS total_returns, 
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(sr.sr_return_quantity) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
total_returned_items AS (
    SELECT sr_item_sk,
           COUNT(*) AS total_quantity_returned
    FROM store_returns
    GROUP BY sr_item_sk
),
weekly_sales AS (
    SELECT d.d_year, d.d_week_seq, SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_week_seq
),
store_info AS (
    SELECT w.w_warehouse_id, SUM(ss.ss_sales_price) AS total_sales_store
    FROM store_sales ss 
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk 
    GROUP BY w.w_warehouse_id
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ts.total_quantity_returned, 0) AS total_quantity_returned,
    SUM(ws.total_sales) AS total_sales_web,
    SUM(si.total_sales_store) AS total_sales_store
FROM recent_customers rc
JOIN customer_with_return_info cr ON rc.c_customer_sk = cr.c_customer_sk
JOIN total_returned_items ts ON cr.c_customer_sk = ts.sr_item_sk
JOIN weekly_sales ws ON ws.d_year = 2023 
JOIN store_info si ON si.w_warehouse_id IS NOT NULL
WHERE cr.return_count > 0
GROUP BY rc.c_first_name, rc.c_last_name, cr.total_returns, cr.total_return_amount, ts.total_quantity_returned
HAVING SUM(ws.total_sales) > 5000
ORDER BY total_sales_web DESC, total_return_amount DESC
LIMIT 100;
