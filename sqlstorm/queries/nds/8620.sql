
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
), 
SalesStatistics AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales
    FROM 
        CustomerSales
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        ss.avg_sales,
        ss.max_sales,
        ss.min_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    CROSS JOIN 
        SalesStatistics ss
    WHERE 
        cs.total_sales > ss.avg_sales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.sales_rank
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
