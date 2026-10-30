
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, 
        sr_returned_date_sk
),
TopReturningCustomers AS (
    SELECT 
        rr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rr.total_returns,
        rr.total_return_amount
    FROM 
        RankedReturns rr
    JOIN 
        customer c ON rr.sr_customer_sk = c.c_customer_sk
    WHERE 
        rr.return_rank <= 5
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        t.sr_customer_sk AS rcustomer_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders,
        t.total_returns,
        t.total_return_amount
    FROM 
        TopReturningCustomers t
    LEFT JOIN 
        SalesData s ON t.sr_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cm.total_sales,
    cm.total_orders,
    cm.total_returns,
    cm.total_return_amount,
    (cm.total_sales - cm.total_return_amount) AS net_revenue
FROM 
    CustomerMetrics cm
JOIN 
    customer c ON cm.rcustomer_sk = c.c_customer_sk
ORDER BY 
    net_revenue DESC
LIMIT 10;
