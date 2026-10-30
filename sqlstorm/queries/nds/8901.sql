
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
promotion_summary AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS promo_profit
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name
),
top_customers AS (
    SELECT 
        s.c_customer_id,
        s.total_quantity,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_summary s
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_sales,
    tc.total_orders,
    ps.promo_profit
FROM top_customers tc
LEFT JOIN promotion_summary ps ON ps.promo_profit IS NOT NULL
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
