
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PremiumCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'Premium'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank <= 10
),
ReturnSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    pc.c_customer_sk,
    pc.c_first_name,
    pc.c_last_name,
    pc.total_spent,
    pc.order_count,
    r.total_returns,
    r.total_returned_amount,
    CASE 
        WHEN r.total_returned_amount IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM 
    PremiumCustomers pc
LEFT JOIN 
    ReturnSummary r ON pc.c_customer_sk = r.c_customer_sk
ORDER BY 
    pc.total_spent DESC;
