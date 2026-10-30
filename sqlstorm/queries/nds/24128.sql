WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
store_sales_info AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_items_sold,
        SUM(ss.ss_net_paid) AS total_sales_revenue
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 day'
    )
    GROUP BY ss.ss_store_sk
),
promotions_used AS (
    SELECT 
        ws.ws_order_number,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_order_number
),
final_stats AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_orders,
        ci.total_spent,
        COALESCE(si.total_items_sold, 0) AS total_items_sold,
        COALESCE(si.total_sales_revenue, 0) AS total_sales_revenue,
        COALESCE(pu.promo_count, 0) AS promo_count
    FROM customer_info ci
    LEFT JOIN store_sales_info si ON ci.c_customer_sk = si.ss_store_sk
    LEFT JOIN promotions_used pu ON ci.total_orders = pu.ws_order_number
)
SELECT 
    fs.c_first_name,
    fs.c_last_name,
    fs.total_orders,
    fs.total_spent,
    fs.total_items_sold,
    fs.total_sales_revenue,
    fs.promo_count,
    CASE 
        WHEN fs.total_spent IS NULL THEN 'No Spending Data'
        WHEN fs.total_spent > 1000 THEN 'Gold'
        WHEN fs.total_spent BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM final_stats fs
WHERE fs.total_orders > (
    SELECT AVG(total_orders) FROM final_stats
)
ORDER BY fs.total_spent DESC
LIMIT 50;