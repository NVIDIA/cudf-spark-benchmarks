
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TotalSpend AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(total_spent) AS avg_spent
    FROM 
        RankedCustomers rc
    JOIN 
        customer_demographics cd ON rc.cd_gender = cd.cd_gender AND rc.cd_marital_status = cd.cd_marital_status
    WHERE 
        rank <= 10
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rc.full_name,
    rc.order_count,
    rc.total_spent,
    ts.avg_spent,
    CASE 
        WHEN rc.total_spent > ts.avg_spent THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    RankedCustomers rc
JOIN 
    TotalSpend ts ON rc.cd_gender = ts.cd_gender AND rc.cd_marital_status = ts.cd_marital_status
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC;
