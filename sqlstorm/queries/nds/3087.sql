
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotions_info AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_id
),
weekly_sales AS (
    SELECT 
        d.d_year,
        d.d_week_seq,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_week_seq
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN ci.cd_credit_rating IS NULL THEN 'Unknown'
        ELSE ci.cd_credit_rating
    END AS credit_rating,
    COALESCE(pi.total_orders, 0) AS promo_orders,
    COALESCE(pi.total_net_profit, 0) AS promo_net_profit,
    ws.total_sales,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year < 1990) AS total_customers_born_before_1990
FROM 
    customer_info ci
LEFT JOIN 
    promotions_info pi ON ci.c_customer_sk = pi.p_promo_sk
LEFT JOIN 
    (SELECT 
         d_week_seq, 
         MAX(total_sales) AS total_sales
     FROM 
         weekly_sales 
     GROUP BY 
         d_week_seq) ws ON ws.total_sales = ws.total_sales
WHERE 
    ci.rank <= 10
ORDER BY 
    ci.cd_purchase_estimate DESC
LIMIT 50;
