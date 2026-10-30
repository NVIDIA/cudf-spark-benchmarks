
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), TopSpenders AS (
    SELECT 
        rc.c_customer_id, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.cd_education_status, 
        rc.total_quantity, 
        rc.total_spent
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    t.cd_marital_status, 
    AVG(t.total_spent) AS avg_spent,
    COUNT(t.c_customer_id) AS num_customers,
    MIN(t.total_quantity) AS min_quantity,
    MAX(t.total_quantity) AS max_quantity
FROM 
    TopSpenders t
GROUP BY 
    t.cd_marital_status
ORDER BY 
    avg_spent DESC;
