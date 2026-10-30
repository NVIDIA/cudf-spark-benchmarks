
WITH SalesData AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT w.web_site_id) AS web_sales_count,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY s.s_store_sk, s.s_store_name
), 
MinimalSales AS (
    SELECT 
        s_store_name,
        total_sales
    FROM SalesData
    WHERE sales_rank = 1
), 
SalesAnalysis AS (
    SELECT 
        ms.s_store_name,
        ms.total_sales,
        CASE 
            WHEN ms.total_sales IS NULL THEN 'No Sales'
            WHEN ms.total_sales BETWEEN 0 AND 100 THEN 'Low Sales'
            WHEN ms.total_sales BETWEEN 101 AND 1000 THEN 'Average Sales'
            WHEN ms.total_sales > 1000 THEN 'High Sales'
            ELSE 'Unknown'
        END AS sales_category
    FROM MinimalSales ms
)
SELECT 
    sa.s_store_name,
    sa.total_sales,
    sa.sales_category,
    COALESCE(d.d_day_name, 'Unknown Day') AS sales_day,
    CASE
        WHEN sa.sales_category = 'No Sales' THEN NULL
        ELSE (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_char_count > 100)
    END AS high_traffic_webpages
FROM SalesAnalysis sa
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_net_paid > 0)
WHERE sa.total_sales IS NOT NULL
ORDER BY sa.total_sales DESC
LIMIT 10;
