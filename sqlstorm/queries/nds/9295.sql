WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, 
        hd.hd_income_band_sk, hd.hd_buy_potential
),
sales_summary AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS customer_count,
        SUM(cd.total_sales) AS total_revenue
    FROM 
        customer_details cd
    JOIN 
        income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.c_first_name, cd.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, 
        cd.cd_credit_rating, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    s.cd_gender,
    s.cd_marital_status,
    s.ib_lower_bound AS income_lower,
    s.ib_upper_bound AS income_upper,
    SUM(s.customer_count) AS total_customers,
    SUM(s.total_revenue) AS total_revenue,
    AVG(s.total_revenue / NULLIF(s.customer_count, 0)) AS average_revenue_per_customer
FROM 
    sales_summary s
GROUP BY 
    s.cd_gender, s.cd_marital_status, s.ib_lower_bound, s.ib_upper_bound
ORDER BY 
    total_revenue DESC, total_customers DESC;