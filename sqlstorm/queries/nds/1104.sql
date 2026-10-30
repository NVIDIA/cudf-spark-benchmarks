
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(*) AS promotion_count
    FROM 
        promotion p
    WHERE 
        p.p_start_date_sk < CAST(20230101 AS INTEGER) AND p.p_end_date_sk > CAST(20230101 AS INTEGER)
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(p.promotion_count, 0) AS promotion_count
FROM 
    top_customers tc
LEFT JOIN 
    promotions p ON tc.sales_rank BETWEEN 1 AND 10 
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
