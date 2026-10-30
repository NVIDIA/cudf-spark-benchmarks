
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_spent,
        cp.order_count
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases) 
        AND cp.order_count > 5
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_return_quantity) AS return_count,
        SUM(sr.sr_net_loss) AS total_loss
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    hs.order_count,
    COALESCE(rr.return_count, 0) AS recent_return_count,
    COALESCE(rr.total_loss, 0) AS total_loss
FROM 
    HighSpenders hs
LEFT JOIN 
    RecentReturns rr ON hs.c_customer_sk = rr.sr_customer_sk
ORDER BY 
    hs.total_spent DESC, 
    recent_return_count ASC
LIMIT 10;
