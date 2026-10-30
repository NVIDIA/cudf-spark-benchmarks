
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_quantity,
        ss.total_revenue,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
),
promotions_used AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        p.p_promo_id
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS daily_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_revenue,
    tc.order_count,
    pu.promo_order_count,
    ds.daily_revenue
FROM 
    top_customers tc
LEFT JOIN 
    promotions_used pu ON pu.promo_order_count > 0
LEFT JOIN 
    daily_sales ds ON ds.daily_revenue > 0
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.total_revenue DESC;
