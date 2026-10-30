
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),

top_customers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        customer_data c
)

SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    t.total_orders,
    ia.ib_lower_bound,
    ia.ib_upper_bound
FROM 
    top_customers t
JOIN 
    household_demographics hd ON t.c_customer_sk = hd.hd_demo_sk
JOIN 
    income_band ia ON hd.hd_income_band_sk = ia.ib_income_band_sk
WHERE 
    t.rank <= 10
ORDER BY 
    total_spent DESC;
