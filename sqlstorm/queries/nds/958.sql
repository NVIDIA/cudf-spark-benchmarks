
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    a.c_customer_id,
    a.total_return_quantity,
    a.total_return_amount,
    a.total_sales,
    a.order_count,
    CASE 
        WHEN a.total_sales = 0 THEN NULL 
        ELSE ROUND((a.total_return_amount / NULLIF(a.total_sales, 0)) * 100, 2) 
    END AS return_percentage,
    CASE 
        WHEN a.order_count > 0 THEN AVG(a.total_return_quantity) OVER (PARTITION BY a.order_count)
        ELSE 0 
    END AS avg_return_per_order
FROM 
    AggregateStats a
WHERE 
    a.total_return_quantity > 5 OR a.total_sales > 1000
ORDER BY 
    return_percentage DESC NULLS LAST
LIMIT 50;
