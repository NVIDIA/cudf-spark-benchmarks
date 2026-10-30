
WITH  SalesHierarchy AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS order_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL

    UNION ALL

    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS order_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sales_price IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_item_desc,
        SUM(COALESCE(sh.ws_sales_price, 0) * sh.ws_quantity) AS total_web_sales,
        SUM(COALESCE(cs.cs_sales_price, 0) * cs.cs_quantity) AS total_catalog_sales,
        COUNT(DISTINCT sh.ws_order_number) AS num_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders
    FROM 
        item
    LEFT JOIN 
        (SELECT * FROM SalesHierarchy) sh ON item.i_item_sk = sh.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON item.i_item_sk = cs.cs_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id, item.i_item_desc
),
FilteredSales AS (
    SELECT 
        a.*,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_rank
    FROM 
        AggregatedSales a
    WHERE 
        total_web_sales > 0 OR total_catalog_sales > 0
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_web_sales,
    f.total_catalog_sales,
    f.num_web_orders,
    f.num_catalog_orders,
    f.web_rank,
    f.catalog_rank
FROM 
    FilteredSales f
WHERE 
    (f.web_rank <= 10 OR f.catalog_rank <= 10)
ORDER BY 
    f.web_rank, f.catalog_rank;
