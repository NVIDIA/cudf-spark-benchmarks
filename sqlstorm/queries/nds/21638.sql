
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS SalesRank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS TotalSales,
        MAX(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS MaxSale
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        CASE 
            WHEN rs.SalesRank = 1 THEN 'Top Seller'
            WHEN rs.TotalSales > 1000 THEN 'High Volume'
            ELSE 'Other'
        END AS SalesCategory
    FROM 
        RankedSales rs
    WHERE 
        rs.TotalSales IS NOT NULL
),
ItemDetails AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        fd.ws_sales_price,
        fd.SalesCategory
    FROM 
        FilteredSales fd
    JOIN 
        item i ON fd.ws_item_sk = i.i_item_sk
)

SELECT 
    COALESCE(id.i_item_desc, 'Unknown Item') AS ItemDescription,
    id.ws_sales_price AS SalesPrice,
    COUNT(*) AS SalesCount,
    SUM(CASE WHEN id.SalesCategory = 'Top Seller' THEN 1 ELSE 0 END) AS TopSellers,
    AVG(id.ws_sales_price) AS AvgSalesPrice
FROM 
    ItemDetails id
LEFT JOIN 
    customer c ON c.c_customer_sk = (
        SELECT 
            c_current_cdemo_sk 
        FROM 
            customer 
        WHERE 
            c_current_cdemo_sk IS NOT NULL
            LIMIT 1
    )
GROUP BY 
    id.i_item_desc, id.ws_sales_price
HAVING 
    COUNT(*) > 5
ORDER BY 
    AvgSalesPrice DESC
OFFSET 10;
