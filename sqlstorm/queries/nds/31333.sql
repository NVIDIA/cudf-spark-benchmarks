
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_quantity) > 10
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS monthly_quantity,
        SUM(ws.ws_net_paid) AS monthly_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2022
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.total_quantity,
    sh.total_paid,
    ms.d_year,
    ms.monthly_quantity,
    ms.monthly_revenue
FROM 
    sales_hierarchy sh
FULL OUTER JOIN 
    monthly_sales ms ON sh.rn = 1
WHERE 
    sh.total_paid IS NOT NULL OR ms.monthly_revenue IS NOT NULL
ORDER BY 
    sh.total_paid DESC, ms.monthly_revenue DESC
LIMIT 50;
