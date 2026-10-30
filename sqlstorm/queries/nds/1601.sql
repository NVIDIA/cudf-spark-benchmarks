
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > (SELECT AVG(total_net_profit) FROM sales_summary)
),
store_performance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
),
top_stores AS (
    SELECT 
        sp.s_store_id,
        sp.store_net_profit,
        RANK() OVER (ORDER BY sp.store_net_profit DESC) AS store_rank
    FROM 
        store_performance sp
)
SELECT 
    ss.d_year,
    ss.total_orders,
    ss.total_quantity_sold,
    ss.total_net_profit,
    ss.avg_order_value,
    COALESCE(tc.total_customers, 0) AS top_customer_count,
    COALESCE(ts.store_count, 0) AS top_store_count
FROM 
    sales_summary ss
LEFT JOIN (
    SELECT 
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        top_customers c
) tc ON 1=1
LEFT JOIN (
    SELECT 
        COUNT(*) AS store_count
    FROM 
        top_stores ts
    WHERE 
        ts.store_rank <= 10
) ts ON 1=1
ORDER BY 
    ss.d_year DESC;
