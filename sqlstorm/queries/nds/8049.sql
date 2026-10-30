
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_sales,
    cs.total_orders,
    (CASE WHEN cs.total_orders > 0 THEN cs.total_sales / cs.total_orders ELSE 0 END) AS avg_order_value,
    (CASE WHEN cs.total_returns > 0 THEN cs.total_return_amount / cs.total_returns ELSE 0 END) AS avg_return_value
FROM 
    CustomerSummary cs
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
