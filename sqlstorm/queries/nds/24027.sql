
WITH CTE_CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
CTE_AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_order_count
    FROM 
        CTE_CustomerSales
),
CTE_CustomerSegment AS (
    SELECT 
        cs.c_customer_sk,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < avg.avg_sales THEN 'Below Average'
            WHEN cs.total_sales >= avg.avg_sales THEN 'Above Average'
        END AS sales_segment
    FROM 
        CTE_CustomerSales cs
    CROSS JOIN 
        CTE_AverageSales avg
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    seg.sales_segment,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'NULL SALES'
        ELSE 'VALID SALES'
    END AS sales_validity,
    COALESCE(DENSE_RANK() OVER (ORDER BY cs.total_sales DESC), 0) AS sales_rank
FROM 
    CTE_CustomerSales cs
JOIN 
    CTE_CustomerSegment seg ON cs.c_customer_sk = seg.c_customer_sk
ORDER BY 
    sales_rank DESC,
    cs.total_sales IS NULL, cs.total_sales;
