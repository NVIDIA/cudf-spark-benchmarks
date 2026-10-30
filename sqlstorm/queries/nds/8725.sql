
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss_store_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_sales,
        rs.total_transactions,
        ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) AS rank
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    ts.total_sales,
    ts.total_transactions
FROM 
    TopStores ts
JOIN 
    store s ON ts.ss_store_sk = s.s_store_sk
ORDER BY 
    ts.total_sales DESC;
