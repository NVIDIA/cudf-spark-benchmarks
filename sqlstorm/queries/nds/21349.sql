
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
), TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity
    FROM 
        RankedSales r
    WHERE 
        r.SalesRank = 1
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE((SELECT COUNT(*) 
                  FROM inventory inv 
                  WHERE inv.inv_item_sk = i.i_item_sk 
                  AND inv.inv_quantity_on_hand > 0), 0) AS available_stock
    FROM 
        item i
), CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL 
    GROUP BY 
        sr_item_sk
), AllData AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.available_stock,
        COALESCE(rs.ws_sales_price, 0) AS maximum_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN id.available_stock = 0 THEN 'Out of Stock'
            WHEN cr.total_returns > 0 THEN 'Returned'
            ELSE 'Available' 
        END AS stock_status
    FROM 
        ItemDetails id
    LEFT JOIN 
        TopSales rs ON id.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON id.i_item_sk = cr.sr_item_sk
)
SELECT 
    ad.i_item_sk,
    ad.i_item_desc,
    ad.i_current_price,
    ad.available_stock,
    ad.maximum_price,
    ad.total_returns,
    ad.total_return_amount,
    ad.stock_status,
    CASE 
        WHEN ad.stock_status = 'Returned' 
             THEN 'Check Quality'
        WHEN ad.available_stock > 0 
             AND ad.maximum_price > 100 
             THEN 'Premium Item'
        ELSE 'Regular Item' 
    END AS item_category
FROM 
    AllData ad
WHERE 
    ad.maximum_price BETWEEN 50 AND 500 
    AND ad.total_return_amount IS NOT NULL 
    AND (ad.stock_status = 'Available' OR ad.stock_status = 'Returned')
ORDER BY 
    ad.maximum_price DESC
LIMIT 20;
