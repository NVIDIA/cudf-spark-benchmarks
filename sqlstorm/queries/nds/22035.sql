
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank,
        COALESCE(cd.cd_purchase_estimate / NULLIF(cd.cd_dep_count, 0), 0) AS avg_purchase_per_dependant
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
PromotionInfo AS (
    SELECT 
        p.p_promo_id,
        MAX(p.p_cost) AS max_cost,
        SUM(COALESCE(s.ws_net_paid, 0) - COALESCE(s.ws_ext_discount_amt, 0)) AS total_net
    FROM 
        promotion p
    LEFT JOIN 
        web_sales s ON s.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
),
CustomerStats AS (
    SELECT 
        rc.c_customer_id,
        COUNT(DISTINCT(ws.ws_order_number)) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        CASE 
            WHEN SUM(ws.ws_quantity) > 50 THEN 'High Value'
            WHEN SUM(ws.ws_quantity) BETWEEN 20 AND 50 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        rc.c_customer_id
)
SELECT 
    cs.c_customer_id,
    r.*, 
    COALESCE(pi.max_cost, 0) AS max_promo_cost,
    pi.total_net AS promo_net_revenue,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        WHEN cs.total_spent IS NULL THEN 'Spent Not Available'
        ELSE 'Metrics Available'
    END AS order_status
FROM 
    CustomerStats cs
FULL OUTER JOIN 
    PromotionInfo pi ON cs.order_count > 10
JOIN 
    RankedCustomers r ON cs.c_customer_id = r.c_customer_id
WHERE 
    r.rank <= 5
    AND r.avg_purchase_per_dependant > 0
ORDER BY 
    cs.total_spent DESC NULLS LAST, 
    pi.total_net DESC NULLS FIRST;
