
WITH  CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) as rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
),
RecentSales AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           NTILE(5) OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_band
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
BizarreReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_amt) AS total_return_amt,
           COUNT(sr_return_quantity) AS total_return_qty,
           CASE
               WHEN SUM(sr_return_amt) IS NULL THEN 'No Returns'
               WHEN SUM(sr_return_amt) = 0 THEN 'Zero Returns'
               ELSE 'Some Returns'
           END AS return_status
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_customer_sk
)
SELECT ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status,
       rs.total_sales, rs.order_count, br.total_return_amt, br.total_return_qty,
       CASE 
           WHEN rs.total_sales > 5000 THEN 'High Value'
           WHEN rs.total_sales <= 5000 AND rs.total_sales > 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       COALESCE(br.return_status, 'No Return Activity') AS return_activity
FROM CustomerHierarchy ch
LEFT JOIN RecentSales rs ON ch.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN BizarreReturns br ON ch.c_customer_sk = br.sr_customer_sk
WHERE ch.rnk = 1
  AND (ch.cd_gender = 'F' OR ch.cd_marital_status = 'M')
ORDER BY customer_value DESC, ch.c_last_name ASC;
