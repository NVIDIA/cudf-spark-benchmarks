
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
), 

top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 10
), 

promotion_details AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
), 

null_check AS (
    SELECT 
        COUNT(*) AS null_customer_count
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NULL
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales, 
    tc.order_count,
    pd.p_promo_name, 
    pd.total_discount,
    pd.total_orders,
    nc.null_customer_count
FROM 
    top_customers tc
FULL OUTER JOIN 
    promotion_details pd ON tc.order_count > 5
CROSS JOIN 
    null_check nc
WHERE 
    tc.total_sales IS NOT NULL 
ORDER BY 
    tc.total_sales DESC;
