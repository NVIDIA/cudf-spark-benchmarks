
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > (
            SELECT 
                AVG(total_spent) 
            FROM (
                SELECT 
                    SUM(ws2.ws_net_paid) AS total_spent
                FROM 
                    web_sales ws2
                GROUP BY 
                    ws2.ws_bill_customer_sk
                ) AS avg_spent
        )
),
CustomerStatistics AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        COALESCE(hs.total_spent, 0) AS total_spent,
        rc.customer_rank,
        CASE 
            WHEN rc.customer_rank <= 10 THEN 'Top 10%'
            WHEN rc.customer_rank BETWEEN 11 AND 50 THEN 'Top 50%'
            ELSE 'Others'
        END AS spending_category
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        HighSpenders hs ON rc.c_customer_sk = hs.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.spending_category,
    CASE 
        WHEN cs.spending_category = 'Top 10%' THEN 'VIP Customer'
        WHEN cs.total_spent IS NULL THEN 'Inactive Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    CASE 
        WHEN cs.total_spent IS NOT NULL AND cs.total_spent > (
            SELECT AVG(total_spent) FROM HighSpenders
        ) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_comparison
FROM 
    CustomerStatistics cs
WHERE 
    cs.total_spent IS NOT NULL 
    OR (cs.customer_rank IS NOT NULL AND cs.customer_rank < 100)
ORDER BY 
    cs.total_spent DESC;
