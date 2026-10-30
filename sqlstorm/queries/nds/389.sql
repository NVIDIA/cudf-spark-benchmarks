
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
HighSpenders AS (
    SELECT 
        cos.c_customer_sk,
        cos.c_first_name,
        cos.c_last_name,
        cos.total_quantity,
        cos.total_spent,
        cos.order_count,
        RANK() OVER (ORDER BY cos.total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary cos
    WHERE 
        cos.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_quantity,
    hs.total_spent,
    hs.order_count,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cr.total_returns IS NOT NULL AND cr.total_returns > 0 THEN 'Informed'
        ELSE 'Not Informed' 
    END AS return_status
FROM 
    HighSpenders hs
LEFT JOIN 
    CustomerReturns cr ON hs.c_customer_sk = cr.sr_customer_sk
WHERE 
    hs.rank <= 10
ORDER BY 
    hs.total_spent DESC;
