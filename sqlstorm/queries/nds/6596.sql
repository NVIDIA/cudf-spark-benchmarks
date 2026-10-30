
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_quantity,
        r.total_spent
    FROM 
        RankedCustomers r
    JOIN 
        customer c ON r.c_customer_sk = c.c_customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_quantity,
    t.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(AVG(ws.ws_net_paid_inc_ship), 0) AS avg_spent_per_order
FROM 
    TopSpenders t
JOIN 
    web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    t.c_customer_sk, t.c_first_name, t.c_last_name, t.total_quantity, t.total_spent
ORDER BY 
    total_spent DESC;
