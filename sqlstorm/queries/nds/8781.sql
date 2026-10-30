
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cs.c_customer_sk) AS total_customers
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_gender
),
PromotedSales AS (
    SELECT 
        ps.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        promotion ps
    JOIN 
        web_sales ws ON ps.p_promo_sk = ws.ws_promo_sk
    WHERE 
        ps.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d) 
        AND ps.p_end_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        ps.p_promo_id
)
SELECT 
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.total_customers,
    ps.p_promo_id,
    ps.total_sales
FROM 
    DemographicStats ds
LEFT JOIN 
    PromotedSales ps ON ds.total_customers > 100
ORDER BY 
    ds.total_customers DESC, 
    ps.total_sales DESC;
