
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS pages_accessed
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY 
        c.c_customer_sk
), 
SalesSummary AS (
    SELECT 
        AVG(total_sales) AS avg_total_sales,
        AVG(order_count) AS avg_order_count,
        AVG(pages_accessed) AS avg_pages_accessed
    FROM 
        CustomerSales
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.order_count,
    cs.pages_accessed,
    ss.avg_total_sales,
    ss.avg_order_count,
    ss.avg_pages_accessed
FROM 
    CustomerSales cs
CROSS JOIN 
    SalesSummary ss
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
