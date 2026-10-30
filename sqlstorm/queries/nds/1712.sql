
WITH RevenueAnalysis AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 
        AND w.w_country = 'USA'
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
PromotionStats AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        promotion p 
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
)
SELECT 
    ra.w_warehouse_id,
    ra.d_year,
    ra.total_net_profit,
    ra.total_orders,
    cd.cd_gender,
    cd.customer_count,
    ps.p_promo_name,
    ps.total_net_paid,
    ps.order_count
FROM 
    RevenueAnalysis ra
FULL OUTER JOIN 
    CustomerDemographics cd ON 1=1
FULL OUTER JOIN 
    PromotionStats ps ON ra.d_year BETWEEN 2020 AND 2023
WHERE 
    (ra.total_net_profit IS NOT NULL OR cd.customer_count IS NOT NULL OR ps.total_net_paid IS NOT NULL)
ORDER BY 
    ra.total_net_profit DESC, 
    cd.customer_count DESC, 
    ps.total_net_paid DESC;
