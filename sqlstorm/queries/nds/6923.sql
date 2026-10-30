
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS average_order_value,
        dd.d_year,
        dd.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, dd.d_year, dd.d_month_seq
),
customer_ranking AS (
    SELECT 
        c_customer_id,
        total_quantity_sold,
        total_sales,
        average_order_value,
        DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    cr.c_customer_id,
    cr.total_quantity_sold,
    cr.total_sales,
    cr.average_order_value,
    cr.sales_rank
FROM 
    customer_ranking cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.total_sales DESC, cr.total_quantity_sold DESC;
