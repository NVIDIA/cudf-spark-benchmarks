
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
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
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promotion_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    sd.total_sales,
    sd.total_transactions,
    COALESCE(p.promotion_usage, 0) AS promotion_usage,
    CASE 
        WHEN sd.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales of ', CAST(sd.total_sales AS STRING), ' with ', CAST(sd.total_transactions AS STRING))
    END AS sales_summary
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    promotions p ON p.promotion_usage > 0
WHERE 
    ci.rn = 1 
AND 
    (ci.cd_purchase_estimate > 500 OR ci.cd_gender = 'F')
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
