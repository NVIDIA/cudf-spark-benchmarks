
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        AVG(sr_return_amt) AS AvgReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemsWithReturns AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(ar.TotalReturns, 0) AS TotalReturns,
        COALESCE(ar.AvgReturnAmt, 0) AS AvgReturnAmt,
        CASE 
            WHEN i.i_current_price IS NULL OR i.i_current_price < 0 THEN 'Invalid Price'
            ELSE 'Valid Price'
        END AS PriceStatus
    FROM 
        item i
    LEFT JOIN 
        AggregatedReturns ar ON i.i_item_sk = ar.sr_item_sk
),
FilteredSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price
    FROM 
        RankedSales r
    JOIN 
        ItemsWithReturns it ON r.ws_item_sk = it.i_item_sk
    WHERE 
        it.TotalReturns > 0 AND r.SalesRank <= 5
)
SELECT 
    fs.ws_item_sk,
    it.i_item_desc,
    fs.ws_order_number,
    fs.ws_sales_price,
    it.TotalReturns,
    it.AvgReturnAmt,
    CASE 
        WHEN it.TotalReturns > 0 AND it.AvgReturnAmt > fs.ws_sales_price THEN 'High Return Risk'
        ELSE 'Normal Risk'
    END AS ReturnRisk
FROM 
    FilteredSales fs
JOIN 
    ItemsWithReturns it ON fs.ws_item_sk = it.i_item_sk
ORDER BY 
    it.TotalReturns DESC, fs.ws_sales_price DESC
LIMIT 10;
