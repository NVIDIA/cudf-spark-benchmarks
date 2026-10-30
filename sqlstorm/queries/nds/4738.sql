
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        rr.total_returns,
        rr.total_return_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN RankedReturns rr ON c.c_customer_sk = rr.sr_customer_sk
    WHERE rr.rnk <= 5
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_ship_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.gender,
    tc.marital_status,
    COALESCE(sd.total_sales, 0) AS total_web_sales,
    COALESCE(sd.total_orders, 0) AS total_web_orders,
    COALESCE(tc.total_returns, 0) AS total_returns,
    COALESCE(tc.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN ROUND((COALESCE(tc.total_return_amount, 0) / COALESCE(sd.total_sales, 0)) * 100, 2)
        ELSE NULL
    END AS return_percentage
FROM TopCustomers tc
LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.ws_ship_customer_sk
ORDER BY return_percentage DESC NULLS LAST;
