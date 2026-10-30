
WITH customer_totals AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS distinct_ship_dates
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
date_summary AS (
    SELECT 
        d.d_year,
        AVG(ct.total_spent) AS avg_spent,
        MAX(ct.total_spent) AS max_spent
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        customer_totals ct ON ct.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        d.d_year
),
filtered_customer_totals AS (
    SELECT 
        c.c_customer_id, 
        ct.total_spent
    FROM 
        customer c
    JOIN 
        customer_totals ct ON c.c_customer_sk = ct.c_customer_sk
    WHERE 
        ct.total_spent IS NOT NULL
)
SELECT 
    fct.c_customer_id,
    fct.total_spent,
    ds.avg_spent,
    ds.max_spent,
    CASE 
        WHEN fct.total_spent IS NULL THEN 'No Spend'
        WHEN fct.total_spent < ds.avg_spent THEN 'Below Average'
        ELSE 'Above Average'
    END AS spending_category
FROM 
    filtered_customer_totals fct
CROSS JOIN 
    date_summary ds
WHERE 
    fct.total_spent > (SELECT AVG(total_spent) FROM customer_totals)
ORDER BY 
    fct.total_spent DESC
LIMIT 100;
