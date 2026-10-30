
WITH sales_summary AS (
    SELECT 
        COALESCE(sm.sm_type, 'Unknown') AS shipping_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROUND(AVG(ws.ws_net_paid), 2) AS average_net_paid,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
),
customer_analysis AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchase,
        MAX(cd.cd_dep_count) AS max_dependents,
        MIN(cd.cd_dep_employed_count) AS min_employed_dependents
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
promotional_performance AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name
)
SELECT 
    cs.shipping_type,
    ca.cd_gender,
    ca.customer_count,
    ca.total_estimated_purchase,
    pp.p_promo_name,
    pp.total_sold,
    pp.total_revenue,
    pp.order_count,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exists'
    END AS sales_status
FROM sales_summary cs
FULL OUTER JOIN customer_analysis ca ON cs.total_quantity > 1000
FULL OUTER JOIN promotional_performance pp ON pp.total_revenue > 10000
WHERE (ca.cd_gender IS NOT NULL OR pp.p_promo_name IS NOT NULL)
AND (cs.shipping_type IS NOT NULL OR cs.total_quantity < 500)
ORDER BY cs.total_sales DESC NULLS LAST, ca.customer_count DESC NULLS FIRST
LIMIT 100;
