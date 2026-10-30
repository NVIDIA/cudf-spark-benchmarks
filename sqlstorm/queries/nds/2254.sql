
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_qty,
        COUNT(DISTINCT ws_order_number) AS sales_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
JoinStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(ss.total_sales_qty, 0) AS total_sales_qty,
        CASE 
            WHEN COALESCE(ss.total_sales_qty, 0) > 0 
                THEN CAST(COALESCE(cr.total_returned_qty, 0) AS FLOAT) / COALESCE(ss.total_sales_qty, 0) 
            ELSE NULL 
        END AS return_ratio,
        ss.avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesStats ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    j.c_customer_sk,
    j.total_returned_qty,
    j.total_sales_qty,
    j.return_ratio,
    j.avg_net_profit,
    CASE 
        WHEN j.return_ratio IS NOT NULL AND j.return_ratio > 0.2 THEN 'High Return Ratio'
        WHEN j.return_ratio IS NOT NULL AND j.return_ratio BETWEEN 0.1 AND 0.2 THEN 'Moderate Return Ratio'
        ELSE 'Low Return Ratio'
    END AS return_category 
FROM 
    JoinStats j
WHERE 
    j.avg_net_profit IS NOT NULL 
    AND j.avg_net_profit > (
        SELECT AVG(avg_net_profit) 
        FROM SalesStats
    )
ORDER BY 
    j.return_ratio DESC NULLS LAST
LIMIT 100;
