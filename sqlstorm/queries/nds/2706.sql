
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.total_sales,
        c.store_sales_count,
        c.web_sales_count,
        c.catalog_sales_count,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM CustomerSales c
),
FilteredSales AS (
    SELECT 
        fs.*,
        CASE 
            WHEN fs.total_sales IS NULL THEN 'No Sales'
            WHEN fs.total_sales > 10000 THEN 'High Value Customer'
            WHEN fs.total_sales BETWEEN 1000 AND 10000 THEN 'Mid Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_value_category
    FROM SalesRanked fs
)
SELECT 
    fs.customer_id,
    fs.first_name,
    fs.last_name,
    fs.total_sales,
    fs.store_sales_count,
    fs.web_sales_count,
    fs.catalog_sales_count,
    fs.sales_rank,
    fs.customer_value_category,
    COALESCE(d.d_month_seq, 0) AS sales_month_sequence
FROM FilteredSales fs
LEFT JOIN date_dim d ON fs.total_sales IS NOT NULL AND d.d_date = DATE '2002-10-01'
WHERE fs.sales_rank <= 100
ORDER BY fs.sales_rank;
