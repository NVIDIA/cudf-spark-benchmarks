
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeDistributions AS (
    SELECT 
        h.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MIN(COALESCE(ws.ws_net_paid, 0)) AS min_spent,
        MAX(COALESCE(ws.ws_net_paid, 0)) AS max_spent,
        AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_spent
    FROM 
        household_demographics h
    LEFT JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        h.hd_demo_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    id.customer_count,
    id.min_spent,
    id.max_spent,
    id.avg_spent,
    CASE 
        WHEN rc.rank_spent <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS spending_category,
    (SELECT COUNT(*)
     FROM store s
     WHERE s.s_number_employees IS NULL OR s.s_number_employees < 10
     ) AS small_stores_count
FROM 
    RankedCustomers rc
JOIN 
    IncomeDistributions id ON rc.c_customer_sk = id.hd_demo_sk
WHERE 
    rc.total_spent > (SELECT AVG(total_spent) FROM RankedCustomers)
ORDER BY 
    rc.cd_gender, rc.rank_spent;
