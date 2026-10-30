
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_quantity ELSE 0 END), 0) AS total_store_quantity,
        COALESCE(SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END), 0) AS total_web_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY (total_store_quantity + total_web_quantity) DESC) AS rank_within_gender
    FROM 
        customer_info
),
income_trend AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        web_sales ws ON hd.hd_demo_sk = ws.ws_bill_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
),
top_income_bands AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY avg_net_profit DESC) AS profit_rank
    FROM 
        income_trend
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    rc.total_store_quantity,
    rc.total_web_quantity,
    ti.avg_net_profit,
    ti.order_count,
    CASE 
        WHEN rc.rank_within_gender <= 10 THEN 'Top 10 Gender'
        ELSE 'Below Top 10 Gender'
    END AS gender_rank_category,
    CASE 
        WHEN ti.profit_rank <= 5 THEN 'Top Income Band'
        ELSE 'Other Income Bands'
    END AS income_band_category
FROM 
    ranked_customers rc
LEFT JOIN 
    top_income_bands ti ON rc.cd_purchase_estimate BETWEEN ti.hd_income_band_sk * 1000 AND (ti.hd_income_band_sk + 1) * 1000
WHERE 
    (rc.total_store_quantity > 0 OR rc.total_web_quantity > 0)
    AND (CASE WHEN rc.cd_gender = 'F' THEN rc.cd_marital_status = 'M' ELSE rc.cd_marital_status = 'S' END) 
ORDER BY 
    rc.cd_gender, rc.cd_purchase_estimate DESC;
