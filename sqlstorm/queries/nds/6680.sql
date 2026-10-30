WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451993 AND 2452032  
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
TopSpenders AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.cd_gender,
        cr.cd_marital_status,
        cr.cd_education_status,
        cr.total_spent
    FROM 
        CustomerRanked cr
    WHERE 
        cr.spending_rank <= 10
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.total_spent,
    CASE 
        WHEN ts.cd_gender = 'F' THEN 'Female'
        WHEN ts.cd_gender = 'M' THEN 'Male'
        ELSE 'Other' 
    END AS gender,
    ts.cd_marital_status,
    ts.cd_education_status
FROM 
    TopSpenders ts
ORDER BY 
    ts.total_spent DESC;