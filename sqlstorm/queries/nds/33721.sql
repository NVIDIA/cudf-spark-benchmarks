
WITH  top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY i.i_item_sk, i.i_item_desc
    ORDER BY total_quantity DESC
    LIMIT 10
), sales_summary AS (
    SELECT
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year
), store_sales_summary AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_store_sales
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
), store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.avg_store_sales, 0) AS avg_store_sales
    FROM store s 
    LEFT JOIN store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
)
SELECT 
    ti.i_item_desc,
    ss.total_orders,
    ss.total_sales,
    ss.avg_order_value,
    si.s_store_name,
    si.total_store_sales,
    si.avg_store_sales
FROM top_items ti
CROSS JOIN sales_summary ss
CROSS JOIN store_info si
WHERE ti.total_quantity > 100
AND ss.total_sales IS NOT NULL
AND (si.total_store_sales IS NULL OR si.avg_store_sales > 50)
ORDER BY ss.total_sales DESC, ti.total_quantity DESC;
