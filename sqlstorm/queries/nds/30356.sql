
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_paid,
        cs_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_ship_date_sk DESC)
    FROM 
        catalog_sales
    WHERE 
        cs_sales_price > 0
),
AggregatedSales AS (
    SELECT 
        ws_item_sk AS item_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net
    FROM 
        SalesData
    WHERE 
        rnk = 1
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk AS item_id,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FinalMetrics AS (
    SELECT 
        a.item_id,
        a.total_quantity,
        a.total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt,
        COALESCE(c.total_return_tax, 0) AS total_return_tax,
        (a.total_sales - COALESCE(c.total_return_amt, 0)) AS net_sales
    FROM 
        AggregatedSales a
    LEFT JOIN 
        CustomerReturns c ON a.item_id = c.item_id
)
SELECT 
    item_id,
    total_quantity,
    total_sales,
    total_returns,
    total_return_amt,
    net_sales,
    ROUND((total_sales - total_return_amt) / NULLIF(total_sales, 0) * 100, 2) AS sales_return_rate
FROM 
    FinalMetrics
WHERE 
    net_sales > 0
ORDER BY 
    net_sales DESC
LIMIT 10;
