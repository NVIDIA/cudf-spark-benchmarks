
WITH MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d_year,
        d_month_seq,
        total_sales,
        order_count
    FROM 
        MonthlySales
    WHERE 
        sales_rank <= 3
)
SELECT 
    mm.d_year,
    mm.d_month_seq,
    COALESCE(t.total_sales, 0) AS top_month_sales,
    COALESCE(t.order_count, 0) AS top_month_orders,
    (SELECT COUNT(DISTINCT c.c_customer_sk) 
     FROM customer c 
     WHERE c.c_birth_year BETWEEN 1980 AND 1990) AS millennials_count,
    (SELECT AVG(i.i_current_price) 
     FROM item i 
     WHERE i.i_current_price IS NOT NULL) AS avg_item_price,
    CASE WHEN t.total_sales IS NOT NULL THEN 'Sales Data Available' ELSE 'No Sales Data' END AS sales_data_status
FROM 
    (SELECT DISTINCT d_year, d_month_seq 
     FROM MonthlySales) mm
LEFT JOIN 
    TopMonths t ON mm.d_year = t.d_year AND mm.d_month_seq = t.d_month_seq
ORDER BY 
    mm.d_year, mm.d_month_seq;
