
WITH  CustomerReturns AS (
    SELECT cr_returning_customer_sk,
           SUM(cr_return_quantity) AS total_returned,
           COUNT(DISTINCT cr_order_number) AS return_count,
           ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rn
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT cr.cr_returning_customer_sk AS returning_customer_sk,
           cr.total_returned,
           cr.return_count,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           ROW_NUMBER() OVER (ORDER BY cr.total_returned DESC) AS rank
    FROM CustomerReturns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.total_returned >= 10
),
SaleStatistics AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS sales_count,
           AVG(ws_net_paid) AS average_sale
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT tc.returning_customer_sk,
       tc.total_returned,
       tc.return_count,
       tc.c_first_name,
       tc.c_last_name,
       tc.c_email_address,
       s.total_sales,
       s.sales_count,
       s.average_sale,
       CASE
           WHEN s.total_sales IS NULL THEN 'No Sales'
           WHEN s.total_sales < 1000 THEN 'Low Sales'
           WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
           ELSE 'High Sales'
       END AS sales_category
FROM TopReturningCustomers tc
LEFT JOIN SaleStatistics s ON tc.returning_customer_sk = s.ws_bill_customer_sk
WHERE tc.rank <= 10
ORDER BY tc.total_returned DESC, s.total_sales DESC;
