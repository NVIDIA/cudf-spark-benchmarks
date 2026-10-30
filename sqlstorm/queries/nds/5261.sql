
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
),
RecentPurchases AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_ship_date_sk DESC) AS recent_purchase_rank
    FROM 
        web_sales ws
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    COUNT(r.ws_bill_customer_sk) AS recent_purchase_count,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date
FROM 
    HighSpenders h
LEFT JOIN 
    RecentPurchases r ON h.c_customer_sk = r.ws_bill_customer_sk AND r.recent_purchase_rank <= 5
JOIN 
    date_dim d ON r.ws_ship_date_sk = d.d_date_sk
WHERE 
    h.spend_rank <= 100
GROUP BY 
    h.c_customer_sk, h.c_first_name, h.c_last_name, h.total_spent
ORDER BY 
    h.total_spent DESC;
