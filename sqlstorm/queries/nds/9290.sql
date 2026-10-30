
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        customer_summary cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_spent,
    tc.total_orders
FROM 
    top_customers tc
    JOIN income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    tc.total_spent DESC;
