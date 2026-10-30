WITH base_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        bs.ws_item_sk,
        bs.total_quantity,
        bs.total_revenue,
        RANK() OVER (ORDER BY bs.total_revenue DESC) AS revenue_rank
    FROM base_sales bs
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promotion_sales_count
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_revenue,
    COALESCE(p.promotion_sales_count, 0) AS promotion_count,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.order_count,
    ci.total_spent,
    CASE 
        WHEN ci.total_spent IS NULL THEN 'No Purchases'
        WHEN ci.total_spent < 100 THEN 'Low Value Customer'
        WHEN ci.total_spent BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_segment,
    RANK() OVER (PARTITION BY ci.cd_gender ORDER BY ti.total_revenue DESC) AS item_ranking
FROM top_items ti
LEFT JOIN promotions p ON ti.ws_item_sk = p.p_promo_sk
JOIN customer_info ci ON ci.order_count > 0
WHERE ti.revenue_rank <= 10 
ORDER BY ti.total_revenue DESC, ci.total_spent ASC;