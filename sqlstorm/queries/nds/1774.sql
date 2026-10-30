
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, cd.cd_credit_rating, hd.hd_income_band_sk
),
promotional_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS promo_sales,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        web_sales ws
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.ws_bill_customer_sk
),
profit_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        COALESCE(ps.promo_sales, 0) AS promo_sales,
        COALESCE(ps.promo_order_count, 0) AS promo_order_count
    FROM 
        customer_stats cs
    LEFT JOIN promotional_sales ps ON cs.c_customer_sk = ps.ws_bill_customer_sk
)
SELECT 
    ps.c_customer_sk,
    ps.total_orders,
    ps.total_profit,
    ps.promo_sales,
    ps.promo_order_count,
    (CASE 
        WHEN ps.total_profit IS NULL THEN 'No Profit'
        WHEN ps.total_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit' 
    END) AS profit_category,
    (SELECT 
        COUNT(DISTINCT sr_item_sk) 
     FROM 
        store_returns sr 
     WHERE 
        sr.sr_customer_sk = ps.c_customer_sk) AS return_count
FROM 
    profit_summary ps
ORDER BY 
    ps.total_profit DESC
LIMIT 10;
