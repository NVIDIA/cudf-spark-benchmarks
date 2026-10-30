
WITH  SalesHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price, cs.cs_order_number
),
ReturnAggregate AS (
    SELECT 
        sr_items.sr_item_sk,
        SUM(sr_items.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr_items
    GROUP BY 
        sr_items.sr_item_sk
),
SalesComparison AS (
    SELECT 
        sh.i_item_sk,
        sh.i_item_desc,
        sh.total_sales,
        COALESCE(ra.total_returns, 0) AS total_returns,
        (sh.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales,
        sh.sales_rank
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        ReturnAggregate ra ON sh.i_item_sk = ra.sr_item_sk
)
SELECT 
    sc.i_item_sk,
    sc.i_item_desc,
    sc.total_sales,
    sc.total_returns,
    sc.net_sales,
    CASE 
        WHEN sc.net_sales < 0 THEN 'Loss'
        WHEN sc.net_sales = 0 THEN 'Break-Even'
        ELSE 'Profit'
    END AS sales_status
FROM 
    SalesComparison sc
WHERE 
    sc.sales_rank = 1
ORDER BY 
    sc.net_sales DESC
LIMIT 10;
