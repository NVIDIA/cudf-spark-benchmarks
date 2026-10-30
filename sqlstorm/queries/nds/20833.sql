
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk < 2700 AND 
        (p.p_discount_active = 'Y' OR p.p_channel_dmail = '1')
    GROUP BY 
        p.p_promo_id
),
ranked_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
filtered_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.total_sales
    FROM 
        ranked_customers rc
    WHERE 
        rc.sales_rank <= 10
)
SELECT 
    fc.c_customer_id,
    COALESCE(p.promo_order_count, 0) AS promotion_orders,
    fc.total_sales AS customer_sales,
    CASE 
        WHEN fc.total_sales IS NULL THEN 'No Sales'
        WHEN fc.total_sales > 1000 THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type,
    (SELECT AVG(t_avg.sales) 
     FROM (SELECT 
                total_sales AS sales 
           FROM customer_sales 
           WHERE total_sales IS NOT NULL) AS t_avg) AS avg_sales_overall
FROM 
    filtered_customers fc
LEFT JOIN 
    promotions p ON fc.total_sales > 5000
ORDER BY 
    fc.total_sales DESC;
