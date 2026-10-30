
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        total_sales,
        sales_count,
        NTILE(4) OVER (ORDER BY total_sales) AS sales_quartile
    FROM 
        CustomerSales
),
TopQuartiles AS (
    SELECT 
        sales_quartile,
        AVG(total_sales) AS avg_sales,
        COUNT(*) AS customer_count
    FROM 
        SalesSummary
    GROUP BY 
        sales_quartile
)
SELECT 
    tq.sales_quartile,
    tq.avg_sales,
    tq.customer_count,
    ROUND(AVG(total_sales), 2) AS avg_sales_in_quartile
FROM 
    TopQuartiles tq
JOIN 
    SalesSummary ss ON tq.sales_quartile = ss.sales_quartile
GROUP BY 
    tq.sales_quartile, tq.avg_sales, tq.customer_count
ORDER BY 
    tq.sales_quartile;
