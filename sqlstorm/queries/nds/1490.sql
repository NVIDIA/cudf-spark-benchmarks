
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        SUM(ws.ws_quantity) AS total_items,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.total_items
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > 1000
),
AverageSpent AS (
    SELECT 
        AVG(total_spent) AS avg_spent
    FROM 
        HighSpenders
)
SELECT 
    hs.c_customer_sk,
    hs.total_orders,
    hs.total_spent,
    hs.total_items,
    CASE 
        WHEN hs.total_spent > avg.avg_spent THEN 'Above Average'
        WHEN hs.total_spent IS NULL THEN 'No Spending'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    HighSpenders hs
CROSS JOIN 
    AverageSpent avg
WHERE 
    hs.total_items > (SELECT AVG(total_items) FROM HighSpenders)
ORDER BY 
    hs.total_spent DESC;
