
WITH customer_totals AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        ct.total_sales,
        ct.order_count,
        ct.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY ct.total_sales DESC) AS sales_rank
    FROM 
        customer_totals ct
    JOIN 
        customer c ON ct.c_customer_sk = c.c_customer_sk
    WHERE 
        ct.total_sales > 1000
),
promotion_details AS (
    SELECT 
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
    HAVING 
        COUNT(ws.ws_order_number) > 5
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_sales,
    hvc.order_count,
    pd.p_promo_name,
    pd.promo_order_count
FROM 
    high_value_customers hvc
LEFT JOIN 
    promotion_details pd ON pd.promo_order_count > 0
ORDER BY 
    hvc.sales_rank
LIMIT 10;
