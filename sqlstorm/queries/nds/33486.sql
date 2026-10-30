
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 20230101 
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cs.total_sales, 0) AS total_sales,
        cs.total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_sales,
    cs.total_orders,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    CASE 
        WHEN cs.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Rare Returner'
    END AS return_behavior
FROM 
    CustomerStats cs
WHERE 
    cs.total_sales > 0
ORDER BY 
    cs.total_sales DESC,
    cs.total_returns ASC
LIMIT 10;
