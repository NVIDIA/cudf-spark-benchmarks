
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_spent,
        AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_web_spent,
        MAX(ws.ws_net_paid) AS max_web_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        AVG(COALESCE(sr_return_amt, 0)) AS avg_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_orders,
        cs.total_web_spent,
        cs.avg_web_spent,
        cs.max_web_order,
        COALESCE(rs.total_store_returns, 0) AS total_store_returns,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(rs.avg_returned_amount, 0) AS avg_returned_amount
    FROM 
        CustomerStats cs
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_web_orders,
    cs.total_web_spent,
    cs.avg_web_spent,
    cs.max_web_order,
    cs.total_store_returns,
    cs.total_returned_amount,
    cs.avg_returned_amount
FROM 
    CombinedStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    (cs.total_web_spent > 1000 OR cs.total_store_returns > 5)
    AND c.c_birth_year > 1980
ORDER BY 
    cs.total_web_spent DESC,
    cs.total_store_returns ASC
LIMIT 50;
