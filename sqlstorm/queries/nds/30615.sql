
WITH  sales_hierarchy AS (
    SELECT 
        s_store_name,
        ss_amounts.net_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY ss_sold_date_sk DESC) AS rn
    FROM (
        SELECT 
            ss_store_sk,
            SUM(ss_net_paid) AS net_sales,
            ss_sold_date_sk
        FROM store_sales
        GROUP BY ss_store_sk, ss_sold_date_sk
    ) AS ss_amounts
    JOIN store ON ss_amounts.ss_store_sk = store.s_store_sk
),
top_sales AS (
    SELECT 
        s_store_name,
        net_sales,
        ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS rank
    FROM sales_hierarchy
    WHERE rn <= 30
)
SELECT 
    sh.s_store_name,
    sh.net_sales,
    CASE 
        WHEN sh.net_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    'Store Name: ' || sh.s_store_name || ', Sales Amount: ' || COALESCE(CAST(sh.net_sales AS STRING), '0.00') AS sales_info
FROM top_sales sh
FULL OUTER JOIN (
    SELECT 
        w.w_warehouse_name, 
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    JOIN warehouse w ON web_sales.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_name
) AS web_total ON sh.s_store_name = web_total.w_warehouse_name
WHERE sh.rank <= 10 OR web_total.total_quantity IS NOT NULL
ORDER BY sh.net_sales DESC NULLS LAST;
