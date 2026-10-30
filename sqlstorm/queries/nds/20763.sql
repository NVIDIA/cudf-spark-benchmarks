
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_sales_price
    FROM 
        sales_summary ss
    WHERE 
        ss.sales_rank <= 10
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(SR.sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN 
        store_returns SR ON ss.ss_item_sk = SR.sr_item_sk AND ss.ss_ticket_number = SR.sr_ticket_number
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    si.s_store_name,
    tsi.total_sales,
    si.distinct_items_sold,
    CASE 
        WHEN tsi.total_sales IS NULL THEN 'No Sales'
        WHEN tsi.total_sales > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY si.total_returns DESC) AS returns_rank
FROM 
    store_info si
INNER JOIN 
    (SELECT 
        ts.ws_item_sk,
        SUM(ts.total_sales) AS total_sales
     FROM 
        top_sales ts
     GROUP BY 
        ts.ws_item_sk) tsi ON si.distinct_items_sold > 5
WHERE 
    si.distinct_items_sold IS NOT NULL
ORDER BY 
    sales_category, si.s_store_name
LIMIT 10 OFFSET 5;
