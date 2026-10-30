
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE 
            WHEN p.p_discount_active = 'Y' THEN ws.ws_ext_sales_price 
            ELSE 0 
        END) AS total_discounted_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_discounted_sales DESC) AS gender_rank
    FROM 
        ranked_customers
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_discounted_sales,
    tc.total_orders,
    (SELECT COUNT(*) FROM store s WHERE s.s_country = 'USA') AS total_stores_in_us,
    (SELECT AVG(ss.ss_net_profit) FROM store_sales ss) AS avg_net_profit_per_sale
FROM 
    top_customers tc
WHERE 
    tc.gender_rank <= 10 AND
    tc.total_orders >= 5
ORDER BY 
    tc.total_discounted_sales DESC;
