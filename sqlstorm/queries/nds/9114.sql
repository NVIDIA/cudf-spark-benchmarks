
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
promotions_summary AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS usage_count,
        SUM(ws.ws_ext_sales_price) AS total_sales_generated
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.total_orders,
    cs.total_returns,
    ps.p_promo_id,
    ps.p_promo_name,
    ps.usage_count,
    ps.total_sales_generated
FROM 
    customer_summary cs
LEFT JOIN 
    promotions_summary ps ON cs.total_spent > 1000 AND ps.usage_count > 0
WHERE 
    cs.total_orders > 5
ORDER BY 
    cs.total_spent DESC, ps.total_sales_generated DESC
LIMIT 100;
