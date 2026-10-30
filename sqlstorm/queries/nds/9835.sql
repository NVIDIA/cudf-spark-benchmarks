
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_id
),
SalesComparison AS (
    SELECT 
        cs.c_customer_id,
        ss.s_store_id,
        cs.total_web_sales,
        ss.total_store_sales,
        CASE 
            WHEN cs.total_web_sales > ss.total_store_sales THEN 'More Online Sales'
            WHEN cs.total_web_sales < ss.total_store_sales THEN 'More Store Sales'
            ELSE 'Equal Sales'
        END AS sales_comparison
    FROM 
        CustomerSales cs
    JOIN 
        StoreSales ss ON cs.total_orders > 0
)
SELECT 
    COUNT(*) AS comparison_count,
    sales_comparison,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesComparison
GROUP BY 
    sales_comparison
ORDER BY 
    comparison_count DESC;
