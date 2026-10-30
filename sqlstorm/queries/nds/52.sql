
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_product_name, 
        COALESCE(i.i_current_price, 0) AS current_price
    FROM 
        item i
),
StoreSales AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS store_total_quantity,
        SUM(ss_ext_sales_price) AS store_total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
)
SELECT 
    ds.d_date AS sales_date,
    id.i_item_id,
    id.i_product_name,
    COALESCE(ss.total_quantity, 0) AS web_total_quantity,
    COALESCE(ss.total_sales, 0) AS web_total_sales,
    COALESCE(st.store_total_quantity, 0) AS store_total_quantity,
    COALESCE(st.store_total_sales, 0) AS store_total_sales,
    (COALESCE(ss.total_sales, 0) + COALESCE(st.store_total_sales, 0)) AS combined_sales
FROM 
    date_dim ds
LEFT JOIN 
    SalesSummary ss ON ds.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    ItemDetails id ON ss.ws_item_sk = id.i_item_sk
LEFT JOIN 
    StoreSales st ON ds.d_date_sk = st.ss_sold_date_sk AND id.i_item_sk = st.ss_item_sk
WHERE 
    ds.d_year = 2023
ORDER BY 
    sales_date, web_total_sales DESC
LIMIT 100;
