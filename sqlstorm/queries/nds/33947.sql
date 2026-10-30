
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        CASE 
            WHEN COUNT(DISTINCT ss.ss_ticket_number) > 0 THEN AVG(ss.ss_ext_sales_price)
            ELSE NULL
        END AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesGrowth AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        LAG(cs.total_sales, 1) OVER (ORDER BY cs.c_customer_sk) AS previous_sales,
        CASE 
            WHEN LAG(cs.total_sales, 1) OVER (ORDER BY cs.c_customer_sk) IS NULL THEN NULL
            ELSE (cs.total_sales - LAG(cs.total_sales, 1) OVER (ORDER BY cs.c_customer_sk)) / LAG(cs.total_sales, 1) OVER (ORDER BY cs.c_customer_sk) * 100
        END AS sales_growth_percentage
    FROM 
        CustomerSales cs
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_orders,
    s.avg_order_value,
    COALESCE(sg.sales_growth_percentage, 0) AS growth_percentage,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN s.total_sales > 10000 THEN 'High Buyer'
        WHEN s.avg_order_value IS NULL THEN 'No Orders'
        ELSE 'Regular Buyer'
    END AS customer_type
FROM 
    CustomerSales s
LEFT JOIN 
    SalesGrowth sg ON s.c_customer_sk = sg.c_customer_sk
WHERE 
    s.total_sales > 1000
ORDER BY 
    s.total_sales DESC;
