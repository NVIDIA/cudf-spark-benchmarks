
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM 
        customer AS c
        LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_store_revenue,
        COUNT(ss.ss_ticket_number) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_store_sk
),
promotion_effectiveness AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_revenue
    FROM
        promotion AS p
        JOIN web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_revenue,
    cs.avg_quantity_per_order,
    ss.total_store_revenue,
    ss.total_store_sales,
    ss.avg_sales_price,
    pe.promo_order_count,
    pe.promo_revenue
FROM 
    customer_sales AS cs
    JOIN store_sales_summary AS ss ON cs.c_customer_sk = ss.ss_store_sk
    LEFT JOIN promotion_effectiveness AS pe ON cs.c_customer_sk = pe.promo_order_count
ORDER BY 
    cs.total_revenue DESC
LIMIT 100;
