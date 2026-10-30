
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS order_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        sc.ws_bill_customer_sk,
        c_first_name, 
        c_last_name,
        total_orders,
        total_sales
    FROM SalesCTE sc
    JOIN customer c ON sc.ws_bill_customer_sk = c.c_customer_sk
    WHERE order_rank <= 10
),
AggregateReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
CompleteCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(tc.total_orders, 0) AS orders_count,
        COALESCE(tc.total_sales, 0) AS total_sales,
        COALESCE(ar.total_returns, 0) AS returns_count,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM customer c
    LEFT JOIN TopCustomers tc ON c.c_customer_sk = tc.ws_bill_customer_sk
    LEFT JOIN AggregateReturns ar ON c.c_customer_sk = ar.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    c.orders_count,
    c.total_sales,
    c.returns_count,
    c.total_return_amount,
    CASE 
        WHEN c.total_sales > 0 THEN (c.total_return_amount / c.total_sales) * 100 
        ELSE 0 
    END AS returns_percentage
FROM CompleteCustomerData c
WHERE c.orders_count > 0
ORDER BY c.total_sales DESC
LIMIT 100;
