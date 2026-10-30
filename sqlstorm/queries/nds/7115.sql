
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),

DateRange AS (
    SELECT 
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),

PromotionSummary AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    JOIN 
        DateRange dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)

SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_spent,
    ps.promo_order_count,
    ps.promo_revenue
FROM 
    CustomerSummary cs
LEFT JOIN 
    PromotionSummary ps ON cs.total_orders > 0
ORDER BY 
    cs.total_spent DESC, ps.promo_revenue DESC
LIMIT 100;
