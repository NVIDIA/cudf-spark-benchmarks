
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
RankedSales AS (
    SELECT
        sales.ws_item_sk,
        sales.total_quantity,
        sales.total_sales,
        ROW_NUMBER() OVER (PARTITION BY sales.ws_item_sk ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        SalesCTE AS sales
),
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        ia.inv_quantity_on_hand,
        COALESCE(s.total_quantity, 0) AS sold_quantity,
        COALESCE(s.total_sales, 0) AS sales_amount
    FROM 
        item i
    LEFT JOIN inventory ia ON i.i_item_sk = ia.inv_item_sk
    LEFT JOIN RankedSales s ON i.i_item_sk = s.ws_item_sk
    WHERE 
        s.sales_rank = 1 OR s.sales_rank IS NULL
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_brand,
    id.inv_quantity_on_hand,
    id.sold_quantity,
    id.sales_amount,
    CASE 
        WHEN id.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
        WHEN id.inv_quantity_on_hand < 10 THEN 'Low Stock'
        ELSE 'In Stock' 
    END AS stock_status,
    CONCAT('Item:', id.i_item_desc, ', Brand:', id.i_brand) AS item_summary
FROM 
    ItemDetails id
WHERE 
    (id.sold_quantity > 100 OR id.sales_amount > 1000)
ORDER BY 
    id.sales_amount DESC
LIMIT 100;
