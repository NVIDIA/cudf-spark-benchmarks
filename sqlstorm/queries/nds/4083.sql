
WITH CustomerReturns AS (
    SELECT 
        customer.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returns
    FROM customer
    LEFT JOIN store_returns sr ON customer.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON customer.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN catalog_returns cr ON customer.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY customer.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(ws_order_number) AS total_web_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_store_returns,
        cr.total_web_returns,
        cr.total_catalog_returns,
        COALESCE(sd.total_web_sales, 0) AS total_web_sales,
        sd.total_web_orders
    FROM CustomerReturns cr
    JOIN customer c ON cr.c_customer_id = c.c_customer_id
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_store_returns,
    tc.total_web_returns,
    tc.total_catalog_returns,
    tc.total_web_sales,
    tc.total_web_orders,
    CASE 
        WHEN tc.total_web_orders > 0 THEN ROUND(tc.total_web_sales / tc.total_web_orders, 2)
        ELSE NULL 
    END AS avg_order_value,
    RANK() OVER (ORDER BY tc.total_web_sales DESC) AS sales_rank
FROM TopCustomers tc
WHERE (tc.total_store_returns > 5 OR tc.total_web_returns > 5)
ORDER BY sales_rank;
