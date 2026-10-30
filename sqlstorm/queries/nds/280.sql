
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_purchase
    FROM 
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotional_summary AS (
    SELECT 
        p.p_promo_name,
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        COALESCE(ps.total_sales, 0) AS total_promotional_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer_summary cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        (SELECT 
            c.c_customer_sk, 
            SUM(cs.cs_sales_price) AS total_sales 
         FROM 
            customer c
         JOIN 
            catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
         GROUP BY 
            c.c_customer_sk) ps ON cs.c_customer_sk = ps.c_customer_sk
    WHERE 
        cs.rank_purchase <= 10
    GROUP BY 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        cs.cd_purchase_estimate, 
        ps.total_sales
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS household_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    CASE 
        WHEN tc.total_promotional_sales > (SELECT AVG(total_sales) FROM promotional_summary) THEN 'Above Average'
        ELSE 'Below Average'
    END AS promo_sales_comparison,
    COALESCE(id.household_count, 0) AS households_in_income_band
FROM 
    top_customers tc
LEFT JOIN 
    income_distribution id ON tc.cd_purchase_estimate BETWEEN id.ib_lower_bound AND id.ib_upper_bound
ORDER BY 
    tc.cd_purchase_estimate DESC;
