
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        total_sales
    FROM 
        SalesData
    WHERE 
        rn = 1
),
ReturnsData AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FinalSales AS (
    SELECT 
        t.ws_item_sk, 
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        TopSales t
    LEFT JOIN 
        ReturnsData r ON t.ws_item_sk = r.wr_item_sk
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales FROM web_sales GROUP BY ws_item_sk) s ON t.ws_item_sk = s.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    i.i_item_desc,
    i.i_current_price,
    (CASE 
        WHEN f.net_sales > 0 THEN f.net_sales / NULLIF(f.total_sales, 0) 
        ELSE NULL 
    END) AS sales_ratio
FROM 
    FinalSales f
JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
WHERE 
    f.net_sales > 0
ORDER BY 
    f.net_sales DESC
LIMIT 10;
