
WITH  sales_rank AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        c.c_customer_id, d.d_year, c.c_first_name, c.c_last_name
), 
promotions_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.orders_count,
    COALESCE(pr.num_orders, 0) AS promo_orders,
    COALESCE(pr.total_discounts, 0) AS total_discounts,
    ROW_NUMBER() OVER (ORDER BY tc.total_spent DESC) AS customer_rank
FROM 
    top_customers tc
LEFT JOIN 
    promotions_summary pr ON pr.num_orders > 0 
WHERE 
    tc.total_spent > (
        SELECT AVG(total_sales)
        FROM sales_rank
    )
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
