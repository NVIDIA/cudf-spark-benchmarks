
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        dd.d_year,
        dd.d_month_seq
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id, dd.d_year, dd.d_month_seq
), 
ranking AS (
    SELECT 
        c_customer_id,
        total_quantity,
        total_sales,
        avg_sales_price,
        order_count,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.c_customer_id,
    r.total_quantity,
    r.total_sales,
    r.avg_sales_price,
    r.order_count,
    r.sales_rank
FROM 
    ranking AS r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank, r.total_sales DESC;
