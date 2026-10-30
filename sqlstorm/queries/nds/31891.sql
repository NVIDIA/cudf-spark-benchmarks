
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesAnalysis AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        s.total_orders,
        (s.total_sales - COALESCE(r.total_return_amt, 0)) AS net_sales,
        CASE 
            WHEN s.total_sales = 0 THEN 0 
            ELSE (COALESCE(r.total_return_amt, 0) / s.total_sales) * 100 
        END AS return_rate
    FROM 
        SalesCTE s
    LEFT JOIN 
        CustomerReturns r ON s.ws_item_sk = r.wr_item_sk
    WHERE 
        s.rnk <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sa.total_sales,
    sa.total_return_amt,
    sa.net_sales,
    sa.return_rate
FROM 
    SalesAnalysis sa
JOIN 
    item i ON sa.ws_item_sk = i.i_item_sk
ORDER BY 
    sa.net_sales DESC;
