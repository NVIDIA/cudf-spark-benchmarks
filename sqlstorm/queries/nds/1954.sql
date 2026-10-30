
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS number_of_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
MergedData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.average_profit, 0) AS average_profit,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.customer_sk
)
SELECT 
    md.c_customer_sk,
    md.total_returns,
    md.total_return_amt,
    md.total_sales,
    md.average_profit,
    md.total_orders,
    CASE 
        WHEN md.total_sales = 0 THEN NULL 
        ELSE ROUND((md.total_return_amt / md.total_sales) * 100, 2) 
    END AS return_rate_percentage,
    RANK() OVER (ORDER BY md.total_sales DESC) AS rank_by_sales
FROM 
    MergedData md
WHERE 
    md.total_orders > 5 
    AND md.total_returns > 0
ORDER BY 
    md.total_sales DESC 
LIMIT 100;
