
WITH sales_summary AS (
    SELECT
        w.w_warehouse_name,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY w.w_warehouse_name, p.p_promo_name
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
)
SELECT 
    s.w_warehouse_name,
    s.p_promo_name,
    s.total_sales,
    s.total_revenue,
    s.total_quantity,
    s.avg_order_value,
    c.c_customer_id,
    ci.gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate
FROM sales_summary s
JOIN customer_info ci ON ci.customer_rank <= 10
LEFT JOIN customer c ON c.c_customer_id = (
    SELECT c_customer_id 
    FROM customer 
    WHERE c_customer_sk IN (
        SELECT sr_customer_sk 
        FROM store_returns
        WHERE sr_return_quantity > 0 
        AND sr_store_sk IN (
            SELECT s_store_sk 
            FROM store 
            WHERE s_store_name LIKE '%Main%'
        )
    )
    ORDER BY c_birth_year DESC
    LIMIT 1
)
WHERE s.revenue_rank <= 5
ORDER BY s.total_revenue DESC;
