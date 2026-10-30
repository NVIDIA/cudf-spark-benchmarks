
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), SalesRank AS (
    SELECT 
        csk,
        total_spent,
        order_count,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        (SELECT 
            c_customer_sk AS csk, 
            total_spent, 
            order_count 
        FROM 
            CustomerSales) AS RankedSales
    WHERE 
        total_spent IS NOT NULL
)
SELECT 
    cr.csk,
    cr.total_spent,
    cr.order_count,
    cr.rank,
    (SELECT COUNT(*) FROM SalesRank WHERE rank <= cr.rank) AS cumulative_count
FROM 
    SalesRank cr
WHERE 
    cr.rank <= 10
UNION ALL
SELECT 
    NULL AS csk,
    NULL AS total_spent,
    NULL AS order_count,
    NULL AS rank,
    COUNT(*) AS cumulative_count
FROM 
    SalesRank
WHERE 
    rank > 10
ORDER BY 
    rank;
