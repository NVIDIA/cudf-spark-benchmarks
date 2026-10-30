
WITH SalesData AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_quantity) AS total_units_sold,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_net_paid) AS average_sale,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        s.s_store_id
), CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), PromotionEffect AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_net_paid) AS promo_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    sd.s_store_id,
    sd.total_units_sold,
    sd.total_revenue,
    sd.average_sale,
    ca.total_spent,
    ca.total_orders,
    pe.promo_orders,
    pe.promo_revenue
FROM 
    SalesData sd
JOIN 
    CustomerAnalysis ca ON sd.total_revenue > 10000
LEFT JOIN 
    PromotionEffect pe ON pe.promo_revenue > 1000
ORDER BY 
    sd.total_revenue DESC;
