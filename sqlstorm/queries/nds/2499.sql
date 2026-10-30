
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
BestCustomers AS (
    SELECT
        *,
        CASE 
            WHEN total_profit IS NULL THEN 'NO SALES'
            WHEN total_profit < 1000 THEN 'LOW SPENDER'
            ELSE 'HIGH SPENDER'
        END AS Spending_Category
    FROM 
        CustomerRanked
    WHERE 
        gender_rank <= 10
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_customer_sk,
    cd.cd_gender,
    bc.Spending_Category,
    bc.total_profit
FROM 
    BestCustomers bc
JOIN 
    customer c ON bc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    total_profit DESC
LIMIT 20;
