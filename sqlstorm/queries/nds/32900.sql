
WITH  CustomerReturns AS (
    SELECT sr_customer_sk,
           COUNT(*) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_value,
           ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           CD.cd_gender,
           CR.total_returns,
           CR.total_return_value
    FROM customer c
    JOIN customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
    WHERE CR.rn = 1
),
DailySales AS (
    SELECT d.d_date,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders,
           AVG(ws.ws_sales_price) AS avg_order_value
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
SalesRanking AS (
    SELECT ds.d_date,
           ds.total_sales,
           ds.total_orders,
           ds.avg_order_value,
           RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM DailySales ds
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.cd_gender,
       COALESCE(sr.total_sales, 0) AS total_sales,
       COALESCE(sr.total_orders, 0) AS total_orders,
       sr.avg_order_value,
       sr.sales_rank
FROM TopCustomers tc
LEFT JOIN SalesRanking sr ON sr.sales_rank = 1
WHERE tc.total_return_value > (SELECT AVG(total_return_value) FROM CustomerReturns)
  AND tc.cd_gender = 'F'
ORDER BY tc.c_last_name, tc.c_first_name;
