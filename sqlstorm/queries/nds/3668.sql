WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS RankSales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451180 AND 2451350 
),
HighDiscounts AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        (cs.cs_list_price - cs.cs_ext_sales_price) AS DiscountAmount,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY (cs.cs_list_price - cs.cs_ext_sales_price) DESC) AS RankDiscount
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2451180 AND 2451350
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturnQty,
        AVG(sr_return_amt_inc_tax) AS AvgReturnAmount,
        COUNT(*) AS ReturnCount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    i.i_item_id, 
    COALESCE(r.RankSales, 0) AS TopSalesRank,
    COALESCE(h.RankDiscount, 0) AS TopDiscountRank,
    COALESCE(t.TotalReturnQty, 0) AS TotalReturnsQuantity,
    COALESCE(t.AvgReturnAmount, 0) AS AverageReturnAmount
FROM 
    item i
LEFT JOIN RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.RankSales = 1
LEFT JOIN HighDiscounts h ON i.i_item_sk = h.cs_item_sk AND h.RankDiscount = 1
LEFT JOIN TotalReturns t ON i.i_item_sk = t.sr_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
ORDER BY 
    i.i_item_id;