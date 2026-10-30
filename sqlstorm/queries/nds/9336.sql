
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_units,
        AVG(ss.ss_sales_price) AS avg_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        d.d_year
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        s.s_store_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)

SELECT 
    ss.s_store_id,
    ss.total_sales,
    ss.total_units,
    ss.avg_price,
    cs.total_purchases,
    cs.total_spent,
    ps.promo_orders,
    ps.promo_sales
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON cs.total_spent > 1000
LEFT JOIN 
    promotion_summary ps ON ps.promo_sales > 5000
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC
LIMIT 100;
