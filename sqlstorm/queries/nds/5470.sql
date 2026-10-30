
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
),
best_customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.total_quantity,
        ci.total_spent,
        RANK() OVER (ORDER BY ci.total_spent DESC) AS rank
    FROM 
        customer_info ci
    JOIN 
        customer c ON ci.c_customer_sk = c.c_customer_sk
)
SELECT 
    b.customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.total_quantity,
    b.total_spent,
    ci.ib_lower_bound,
    ci.ib_upper_bound
FROM 
    best_customers b
JOIN 
    customer_info ci ON b.customer_sk = ci.c_customer_sk
WHERE 
    b.rank <= 10
ORDER BY 
    b.total_spent DESC;
