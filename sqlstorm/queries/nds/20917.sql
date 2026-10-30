
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_dep_count) AS rank_by_deps
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ActivePromotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_discount_active,
        COUNT(c.cs_order_number) AS total_orders
    FROM 
        promotion p
    LEFT JOIN 
        (SELECT 
            cs_order_number 
         FROM 
            catalog_sales 
         WHERE 
            cs_sold_date_sk BETWEEN 1 AND 30) c ON p.p_promo_sk = c.cs_order_number
    GROUP BY 
        p.p_promo_sk, p.p_discount_active
),
WebReturnsSummary AS (
    SELECT 
        wr_returned_date_sk,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk
)
SELECT 
    cu.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(SUM(CASE WHEN pm.total_orders IS NULL THEN 0 ELSE 1 END), 0) AS active_promotions_count,
    MAX(rw.total_net_loss) AS highest_net_loss
FROM 
    RankedCustomers cu
JOIN 
    customer_address ca ON cu.c_customer_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ActivePromotions pm ON ws.ws_promo_sk = pm.p_promo_sk
LEFT JOIN 
    WebReturnsSummary rw ON ws.ws_sold_date_sk = rw.wr_returned_date_sk
WHERE 
    cu.rank_by_purchase <= 10
    AND (cu.rank_by_deps IS NULL OR cu.rank_by_deps < 3)
    AND ca.ca_city IS NOT NULL
GROUP BY 
    cu.c_customer_id, ca.ca_city, cu.rank_by_purchase, cu.rank_by_deps
ORDER BY 
    total_profit DESC, order_count ASC
LIMIT 50;
