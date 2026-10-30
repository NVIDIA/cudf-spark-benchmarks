
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        ss.c_customer_id,
        ss.total_items_sold,
        ss.total_sales,
        ss.order_count,
        ss.average_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY ss.total_sales DESC) AS sales_rank,
        ss.d_year
    FROM 
        sales_summary ss
)
SELECT 
    t.c_customer_id,
    t.total_items_sold,
    t.total_sales,
    t.order_count,
    t.average_profit,
    t.sales_rank
FROM 
    top_customers t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.d_year, t.sales_rank;
