
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        AVG(wr_return_quantity) AS avg_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_profit, 0) AS total_profit,
        sd.total_sales,
        CASE 
            WHEN sd.total_profit > 0 
            THEN ROUND((COALESCE(cr.total_return_amount, 0) / sd.total_profit) * 100, 2)
            ELSE 0
        END AS return_percentage
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ra.total_return_amount,
    ra.total_profit,
    ra.total_sales,
    ra.return_percentage,
    CASE 
        WHEN ra.return_percentage > 30 THEN 'High Return'
        WHEN ra.return_percentage BETWEEN 10 AND 30 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    ReturnAnalysis ra
JOIN 
    customer c ON ra.c_customer_id = c.c_customer_id
ORDER BY 
    ra.return_percentage DESC;
