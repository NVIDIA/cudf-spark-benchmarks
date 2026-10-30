
WITH  sales_summary AS (
    SELECT
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
promotion_analysis AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(ws_order_number) AS promo_usage,
        SUM(ws_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
date_range AS (
    SELECT 
        d.d_date_sk,
        MAX(d.d_date) AS max_date,
        MIN(d.d_date) AS min_date
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date_sk  
)
SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.cd_gender AS gender,
    ir.ib_lower_bound AS income_lower_bound,
    ir.ib_upper_bound AS income_upper_bound,
    ss.total_quantity,
    ss.total_sales,
    pa.p_promo_name AS promo_name,
    dr.max_date,
    dr.min_date
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    promotion_analysis pa ON ss.ws_item_sk = pa.p_promo_sk
LEFT JOIN 
    income_band ir ON ci.hd_income_band_sk = ir.ib_income_band_sk
CROSS JOIN 
    date_range dr
WHERE 
    ci.income_rank = 1
AND 
    (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
