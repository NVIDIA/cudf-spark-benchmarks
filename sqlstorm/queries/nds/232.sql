
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotions AS (
    SELECT 
        p.p_promo_sk, 
        p.p_promo_name, 
        p.p_start_date_sk, 
        p.p_end_date_sk,
        COUNT(cs.cs_order_number) AS total_sales
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
sales_summary AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    p.p_promo_name,
    COALESCE(p.total_sales, 0) AS promo_sale_count,
    ss.d_date,
    ss.total_sales,
    ss.total_profit,
    CASE 
        WHEN ci.gender_rank <= 10 THEN 'Top Purchaser'
        ELSE 'Regular Purchaser'
    END AS customer_category
FROM customer_info ci 
LEFT JOIN promotions p ON ci.c_customer_sk = p.p_promo_sk
LEFT JOIN sales_summary ss ON ss.d_date = DATE('2002-10-01') - INTERVAL '1 day'
ORDER BY ss.total_sales DESC, ci.c_last_name, ci.c_first_name;
