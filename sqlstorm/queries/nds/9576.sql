
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        wb.ib_lower_bound,
        wb.ib_upper_bound,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band wb ON hd.hd_income_band_sk = wb.ib_income_band_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, hd.hd_income_band_sk, 
        wb.ib_lower_bound, wb.ib_upper_bound 
),
date_filter AS (
    SELECT 
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
top_customers AS (
    SELECT 
        customer_info.*,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_info
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    tc.hd_income_band_sk,
    tc.ib_lower_bound,
    tc.ib_upper_bound,
    tc.total_spent
FROM 
    top_customers tc
WHERE 
    tc.spending_rank <= 10
    AND EXISTS (
        SELECT 
            1 
        FROM 
            store s 
        JOIN 
            store_returns sr ON s.s_store_sk = sr.sr_store_sk
        JOIN 
            date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
        WHERE 
            sr.sr_customer_sk = tc.c_customer_sk
    )
ORDER BY 
    tc.total_spent DESC;
