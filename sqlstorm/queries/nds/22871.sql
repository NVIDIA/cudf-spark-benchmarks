
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        COALESCE(NULLIF(cd.cd_credit_rating, 'bad'), 'standard') AS effective_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year >= 1990
),
warehouse_shipping AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
    HAVING 
        SUM(ws.ws_net_profit) IS NOT NULL
),
promotional_analysis AS (
    SELECT 
        p.p_promo_id,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS promo_item_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
),
final_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ws.item_count,
        ws.total_net_profit,
        COALESCE(pa.promo_item_quantity, 0) AS total_promo_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.purchase_rank ORDER BY ws.total_net_profit DESC) AS rank_within_gender
    FROM 
        customer_summary cs
    LEFT JOIN 
        warehouse_shipping ws ON cs.c_customer_sk = ws.w_warehouse_sk
    LEFT JOIN 
        promotional_analysis pa ON pa.promo_item_quantity > 0
)
SELECT
    fa.c_customer_sk,
    fa.c_first_name,
    fa.c_last_name,
    fa.item_count,
    fa.total_net_profit,
    fa.total_promo_quantity,
    GREATEST(fa.total_net_profit - 1000, 0) AS adjusted_net_profit,
    CASE 
        WHEN fa.rank_within_gender <= 10 THEN 'Top Customer'
        WHEN fa.rank_within_gender BETWEEN 11 AND 30 THEN 'Average Customer'
        ELSE 'Low Customer'
    END AS customer_classification
FROM 
    final_analysis fa
WHERE 
    fa.total_net_profit IS NOT NULL
ORDER BY 
    fa.total_net_profit DESC
LIMIT 50;
