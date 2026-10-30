
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
        ss_customer_sk,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_customer_sk
),
RETURN_PROFIT AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_net_paid, 0) AS total_net_paid,
        COALESCE(sd.avg_net_profit, 0) AS avg_net_profit,
        CASE 
            WHEN COALESCE(sd.total_net_paid, 0) = 0 THEN NULL 
            ELSE (COALESCE(cr.total_return_amount, 0) / COALESCE(sd.total_net_paid, 0)) * 100 
        END AS return_percentage
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    r.c_customer_id,
    r.total_returns,
    r.total_return_amount,
    r.total_net_paid,
    r.avg_net_profit,
    r.return_percentage
FROM 
    RETURN_PROFIT r
WHERE 
    (r.return_percentage IS NULL OR r.return_percentage > 10) 
    AND (r.total_net_paid > 1000 OR r.total_return_amount > 500)
ORDER BY 
    r.return_percentage DESC NULLS LAST, 
    r.total_net_paid DESC;
