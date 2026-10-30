
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
promotion_data AS (
    SELECT 
        p.p_promo_id, 
        COUNT(DISTINCT p.p_item_sk) AS items_promoted
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.total_quantity,
    cd.total_profit,
    SUM(inv.total_on_hand) AS total_inventory,
    COUNT(DISTINCT pd.p_promo_id) AS active_promotions
FROM 
    customer_data cd
LEFT JOIN 
    inventory_data inv ON cd.total_quantity > 0
LEFT JOIN 
    promotion_data pd ON cd.total_quantity > 100
GROUP BY 
    cd.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, cd.total_quantity, cd.total_profit
ORDER BY 
    cd.total_profit DESC
LIMIT 50;
