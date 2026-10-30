
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_net_profit,
        cs.order_count,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        customer_sales cs
)

SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_dep_count,
    cd.cd_dep_employed_count
FROM 
    ranked_sales rs
JOIN 
    customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
WHERE 
    rs.rank = 1
ORDER BY 
    rs.total_net_profit DESC
LIMIT 20;
