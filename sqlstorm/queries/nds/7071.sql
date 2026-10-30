
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
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
RankedSales AS (
    SELECT 
        c_customer_id AS customer_id,
        total_sales,
        total_quantity,
        order_count,
        d_year,
        d_month_seq,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.customer_id,
    r.total_sales,
    r.total_quantity,
    r.order_count,
    CONCAT(CAST(r.d_year AS STRING), '-', LPAD(CAST(r.d_month_seq AS STRING), 2, '0')) AS year_month,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10 Sales'
        WHEN r.sales_rank <= 50 THEN 'Top 50 Sales'
        ELSE 'Below Top 50'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.d_year = 2022
    AND r.total_sales > 1000
ORDER BY 
    r.d_year, r.d_month_seq, r.sales_rank;
