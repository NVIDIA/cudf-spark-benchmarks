
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS number_of_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY 
        ss_store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.number_of_sales, 0) AS number_of_sales
FROM 
    store s
LEFT JOIN 
    sales_summary ss ON s.s_store_sk = ss.ss_store_sk
ORDER BY 
    total_sales DESC;
