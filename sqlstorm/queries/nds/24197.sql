
WITH active_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(cd.cd_gender, 'Unknown') AS gender,
           DENSE_RANK() OVER (PARTITION BY COALESCE(cd.cd_marital_status, 'N') ORDER BY c.c_customer_id) AS marital_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
total_sales AS (
    SELECT ws_bill_customer_sk AS customer_id, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_bill_customer_sk
),
return_stats AS (
    SELECT sr_customer_sk AS customer_id,
           COUNT(DISTINCT sr_ticket_number) AS return_count,
           SUM(sr_return_amt) AS total_return_amt,
           AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
sales_with_return AS (
    SELECT ac.c_customer_sk, ac.c_first_name, ac.c_last_name, ac.gender, ac.marital_rank,
           COALESCE(ts.total_sales, 0) AS total_sales, 
           COALESCE(rs.return_count, 0) AS return_count,
           COALESCE(rs.total_return_amt, 0) AS total_return_amt
    FROM active_customers ac
    LEFT JOIN total_sales ts ON ac.c_customer_sk = ts.customer_id
    LEFT JOIN return_stats rs ON ac.c_customer_sk = rs.customer_id
),
ranked_sales AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales DESC, return_count ASC) AS sales_rank
    FROM sales_with_return
)
SELECT r.c_first_name, r.c_last_name, r.gender, r.marital_rank, 
       CASE 
           WHEN r.total_sales > 1000 THEN 'High Value Customer'
           WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer' 
       END AS customer_value,
       ROUND(r.total_sales - r.total_return_amt, 2) AS net_sales,
       CASE 
           WHEN r.return_count > 2 THEN 'Frequent Returner'
           ELSE 'Rare Returner' 
       END AS return_behavior
FROM ranked_sales r
WHERE r.sales_rank <= 100
  AND (r.gender = 'M' OR r.gender IS NULL)
ORDER BY net_sales DESC, r.marital_rank ASC;
