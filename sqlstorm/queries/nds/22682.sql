
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as RankDate
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
), 
TotalSales AS (
    SELECT 
        R.ws_item_sk,
        SUM(R.ws_sales_price * R.ws_quantity) as TotalRevenue,
        AVG(R.ws_sales_price) as AvgSalesPrice,
        COUNT(R.ws_quantity) as SalesCount
    FROM 
        RankedSales R
    WHERE 
        R.RankDate = 1
    GROUP BY 
        R.ws_item_sk
)
SELECT 
    ID.i_item_sk,
    ID.i_item_desc,
    ID.i_current_price,
    ID.i_brand,
    COALESCE(TS.TotalRevenue, 0) AS TotalRevenue,
    COALESCE(TS.AvgSalesPrice, 0) AS AvgSalesPrice,
    COALESCE(TS.SalesCount, 0) AS SalesCount,
    CASE 
        WHEN COALESCE(TS.TotalRevenue, 0) = 0 THEN 'No Sales'
        WHEN ID.i_current_price < COALESCE(TS.AvgSalesPrice, 0) THEN 'Below Average Price'
        WHEN ID.i_current_price > COALESCE(TS.AvgSalesPrice, 0) THEN 'Above Average Price'
        ELSE 'Average Price'
    END as PriceComparison
FROM 
    ItemDetails ID
LEFT JOIN 
    TotalSales TS ON ID.i_item_sk = TS.ws_item_sk
WHERE 
    ID.i_item_desc IS NOT NULL
ORDER BY 
    ID.i_brand, TotalRevenue DESC
LIMIT 10;

