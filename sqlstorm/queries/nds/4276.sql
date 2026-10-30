
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
), Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS promo_order_count,
        SUM(cs.cs_net_paid) AS promo_total_revenue
    FROM 
        promotion p
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity,
    cs.total_spent,
    cs.order_count,
    p.p_promo_name,
    p.promo_order_count,
    p.promo_total_revenue,
    d.cd_gender,
    d.cd_marital_status
FROM 
    CustomerStats cs
LEFT JOIN 
    Promotions p ON cs.total_spent > 1000 AND p.promo_order_count > 0
LEFT JOIN 
    Demographics d ON cs.c_customer_sk = d.customer_count
WHERE 
    cs.total_spent IS NOT NULL 
    AND (d.cd_gender = 'M' OR d.cd_marital_status = 'M')
    AND cs.total_quantity > (SELECT AVG(total_quantity) FROM CustomerStats)
ORDER BY 
    cs.total_spent DESC, cs.order_count ASC
LIMIT 100;
