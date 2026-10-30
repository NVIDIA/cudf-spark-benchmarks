
WITH sales_summary AS (
    SELECT 
        d.d_year,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        d.d_year, p.p_promo_name
),
top_promotions AS (
    SELECT 
        d_year,
        p_promo_name,
        total_quantity,
        total_net_paid,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS promo_rank
    FROM 
        sales_summary
)
SELECT 
    d_year,
    p_promo_name,
    total_quantity,
    total_net_paid,
    total_orders
FROM 
    top_promotions
WHERE 
    promo_rank <= 5
ORDER BY 
    d_year, total_net_paid DESC;
