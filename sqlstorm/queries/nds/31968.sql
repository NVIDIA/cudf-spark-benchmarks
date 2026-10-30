
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
), 
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(*) AS sales_count,
        AVG(ws_sales_price) AS avg_price
    FROM 
        SalesCTE
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    a.ws_item_sk, 
    a.total_sales, 
    a.sales_count, 
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.return_count, 0) AS return_count,
    CASE 
        WHEN r.total_returns IS NULL OR r.total_returns = 0 
        THEN 'No Returns' 
        ELSE 'Returns Exist' 
    END AS return_status,
    (a.total_sales - COALESCE(r.total_returns * a.avg_price, 0)) AS net_sales
FROM 
    AggregatedSales a
LEFT JOIN 
    CustomerReturns r ON a.ws_item_sk = r.wr_item_sk
WHERE 
    a.total_sales > 1000
ORDER BY 
    net_sales DESC
LIMIT 10;
