
WITH CustomerSalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages_visited,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
RankedCustomerSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSalesData
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rc.order_count,
    rc.distinct_pages_visited,
    rc.sales_rank
FROM 
    RankedCustomerSales rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.d_year, rc.d_month_seq, rc.sales_rank;
