WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > (
            SELECT 
                MAX(d.d_date_sk)
            FROM 
                date_dim d 
            WHERE 
                d.d_date < cast('2002-10-01' as date) - INTERVAL '1 YEAR'
        )
    GROUP BY 
        sr.sr_customer_sk
),
CustomerMetrics AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_quantity,
        cp.order_count,
        cp.total_spent,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_returned_amt, 0) AS total_returned_amt
    FROM 
        CustomerPurchases cp
    LEFT JOIN 
        RecentReturns rr ON cp.c_customer_sk = rr.sr_customer_sk
)
SELECT 
    cm.c_customer_sk,
    cm.c_first_name,
    cm.c_last_name,
    cm.total_quantity,
    cm.order_count,
    cm.total_spent,
    cm.total_returns,
    cm.total_returned_amt,
    CASE 
        WHEN cm.total_spent > 1000 THEN 'High Value' 
        WHEN cm.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    CustomerMetrics cm
WHERE 
    cm.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM CustomerPurchases
    )
ORDER BY 
    cm.total_spent DESC
LIMIT 100;