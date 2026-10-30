
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_month_seq IN (1, 2, 3)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
), ranked_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.order_count,
    r.avg_sales_price,
    r.unique_web_pages,
    r.sales_rank
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, r.d_month_seq, r.sales_rank;
