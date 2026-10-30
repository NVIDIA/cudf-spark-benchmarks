
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales 
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales 
    GROUP BY cs_item_sk
), 
calendar AS (
    SELECT 
        d_date,
        d_month_seq,
        d_year,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_month_seq) AS month_num
    FROM date_dim
)
SELECT 
    ca.ca_state,
    ROUND(AVG(ss.total_sales), 2) AS avg_sales,
    SUM(ss.total_quantity_sold) AS total_units_sold,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    CASE 
        WHEN AVG(ss.total_sales) IS NULL THEN 'No Sales'
        WHEN SUM(ss.total_quantity_sold) > 1000 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
LEFT JOIN (
    SELECT 
        ws_item_sk,
        total_quantity_sold,
        total_sales 
    FROM sales_summary 
    WHERE total_sales > 0
) ss ON c.c_customer_sk = ss.ws_item_sk
JOIN calendar cd ON cd.d_month_seq = EXTRACT(MONTH FROM TIMESTAMP '2002-10-01 12:34:56') 
GROUP BY ca.ca_state
ORDER BY avg_sales DESC
LIMIT 10;
