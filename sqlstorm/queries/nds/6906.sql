
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
), 
sales_by_promo AS (
    SELECT
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM
        web_sales ws
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY
        p.p_promo_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    sbp.promo_sales
FROM 
    top_customers tc
JOIN 
    sales_by_promo sbp ON tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, sbp.promo_sales DESC;
