
WITH ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), TotalSales AS (
    SELECT 
        item.i_item_id,
        COALESCE(web.total_quantity, 0) AS web_quantity,
        COALESCE(store.total_quantity, 0) AS store_quantity,
        (COALESCE(web.total_sales, 0) + COALESCE(store.total_sales, 0)) AS total_sales
    FROM 
        item AS item
    LEFT JOIN 
        ItemSales AS web ON item.i_item_sk = web.ws_item_sk
    LEFT JOIN 
        StoreSales AS store ON item.i_item_sk = store.ss_item_sk
)
SELECT 
    t.i_item_id,
    t.web_quantity,
    t.store_quantity,
    t.total_sales,
    CASE 
        WHEN t.total_sales >= 1000 THEN 'High Volume'
        WHEN t.total_sales >= 500 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM 
    TotalSales t
ORDER BY 
    t.total_sales DESC;
