
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_id
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, w.w_warehouse_id
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales_value DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_quantity_sold,
    r.total_sales_value,
    r.sales_rank,
    r.w_warehouse_id
FROM 
    ranked_sales AS r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, r.d_month_seq, r.sales_rank;
