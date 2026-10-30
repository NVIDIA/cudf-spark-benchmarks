
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesStatistics AS (
    SELECT 
        AVG(total_sales) AS avg_sales, 
        MAX(total_sales) AS max_sales, 
        MIN(total_sales) AS min_sales,
        AVG(total_orders) AS avg_orders,
        MAX(total_orders) AS max_orders,
        MIN(total_orders) AS min_orders
    FROM 
        CustomerSales
),
BestCustomer AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > (SELECT avg_sales FROM SalesStatistics) 
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    b.c_customer_id,
    b.total_sales,
    s.avg_sales,
    s.max_sales,
    s.min_sales,
    s.avg_orders,
    s.max_orders,
    s.min_orders
FROM 
    BestCustomer b
CROSS JOIN 
    SalesStatistics s
ORDER BY 
    b.total_sales DESC;
