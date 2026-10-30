
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND cd.cd_purchase_estimate IS NOT NULL
), 
promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promotions,
        AVG(CASE WHEN p.p_cost IS NOT NULL THEN p.p_cost ELSE 0 END) AS avg_cost
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_id
), 
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(CASE WHEN ws.ws_net_paid IS NULL THEN 0 ELSE ws.ws_net_paid END) AS total_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    COALESCE(sd.total_quantity, 0) AS web_total_quantity,
    COALESCE(sd.total_net_profit, 0) AS web_total_net_profit,
    COALESCE(sd.total_paid, 0) AS web_total_paid,
    COALESCE(p.active_promotions, 0) AS promo_count,
    p.avg_cost
FROM 
    ranked_customers rc
LEFT JOIN 
    sales_data sd ON sd.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_product_name LIKE '%A%'
    )
LEFT JOIN 
    promotions p ON p.p_promo_id = (
        SELECT p2.p_promo_id
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
        ORDER BY p2.p_response_target DESC
        LIMIT 1 
    )
WHERE 
    rc.purchase_rank <= 10
ORDER BY 
    rc.cd_gender, rc.cd_purchase_estimate DESC;
