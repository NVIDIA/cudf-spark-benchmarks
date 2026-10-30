
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
store_sales_summary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS store_total_quantity,
        SUM(ss_sales_price) AS store_total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
consolidated_sales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_web_quantity,
        COALESCE(s.total_sales, 0.00) AS total_web_sales,
        COALESCE(st.store_total_quantity, 0) AS total_store_quantity,
        COALESCE(st.store_total_sales, 0.00) AS total_store_sales,
        (COALESCE(s.total_sales, 0.00) + COALESCE(st.store_total_sales, 0.00)) AS grand_total_sales
    FROM 
        sales_summary s
    FULL OUTER JOIN 
        store_sales_summary st ON s.ws_item_sk = st.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.total_web_quantity,
    cs.total_web_sales,
    cs.total_store_quantity,
    cs.total_store_sales,
    cs.grand_total_sales,
    CASE 
        WHEN cs.grand_total_sales > 1000 THEN 'High Performer'
        WHEN cs.grand_total_sales > 500 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    consolidated_sales cs
JOIN 
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE 
    cs.grand_total_sales IS NOT NULL
ORDER BY 
    cs.grand_total_sales DESC
LIMIT 50;
