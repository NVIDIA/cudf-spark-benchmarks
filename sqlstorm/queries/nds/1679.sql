
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
ReturnAnalysis AS (
    SELECT 
        cr.c_customer_id,
        cr.total_returns,
        cr.total_return_amount,
        CASE 
            WHEN cr.total_returns > 0 AND hv.total_profit IS NOT NULL THEN 'High Return Customer'
            WHEN cr.total_returns > 0 THEN 'Return Customer'
            ELSE 'New Customer'
        END AS customer_type
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        HighValueCustomers hv ON cr.c_customer_id = hv.c_customer_id
)
SELECT 
    r.customer_type,
    COUNT(*) AS customer_count,
    AVG(r.total_return_amount) AS avg_return_amount,
    SUM(r.total_returns) AS total_returns_sum
FROM 
    ReturnAnalysis r
GROUP BY 
    r.customer_type
ORDER BY 
    customer_count DESC;
