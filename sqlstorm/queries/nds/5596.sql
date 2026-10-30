
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, c.c_customer_id, d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_profit,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
)
SELECT 
    ts.customer_id,
    ts.total_quantity,
    ts.total_sales,
    ts.avg_profit,
    ss.d_year
FROM 
    top_customers ts
JOIN 
    (SELECT DISTINCT d_year FROM sales_summary) AS years ON ts.sales_rank <= 10
JOIN 
    sales_summary ss ON ts.customer_id = ss.c_customer_id
ORDER BY 
    ss.d_year, ts.total_sales DESC;
