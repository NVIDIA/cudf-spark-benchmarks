
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
filtered_customers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        total_profit
    FROM 
        ranked_customers
    WHERE 
        rank <= 5
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    COUNT(*) AS customer_count, 
    SUM(total_profit) AS total_profit_sum,
    AVG(total_profit) AS average_profit
FROM 
    filtered_customers
GROUP BY 
    cd_gender, 
    cd_marital_status
ORDER BY 
    cd_gender, 
    total_profit_sum DESC;
