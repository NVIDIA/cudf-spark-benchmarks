
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent IS NOT NULL
),
LastYearPurchases AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS last_year_total
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    hs.order_count,
    COALESCE(lyp.last_year_total, 0) AS last_year_purchases,
    CASE 
        WHEN hs.order_count > 5 THEN 'Frequent Buyer'
        WHEN hs.total_spent > 1000 THEN 'Big Spender'
        ELSE 'Occasional Buyer'
    END AS customer_category
FROM 
    HighSpenders hs
LEFT JOIN 
    LastYearPurchases lyp ON hs.c_customer_sk = lyp.ws_bill_customer_sk
WHERE 
    hs.spend_rank <= 10
ORDER BY 
    hs.total_spent DESC;
