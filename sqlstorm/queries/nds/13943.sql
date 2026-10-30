
WITH SalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 100
    GROUP BY 
        ss_store_sk
)

SELECT 
    s_store_id,
    s_store_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.transaction_count, 0) AS transaction_count
FROM 
    store s
LEFT JOIN 
    SalesData sd ON s.s_store_sk = sd.ss_store_sk
ORDER BY 
    total_sales DESC;
