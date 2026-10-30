
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        r.total_sales,
        r.sales_rank
    FROM 
        item i
    JOIN 
        RankedSales r ON i.i_item_sk = r.ws_item_sk
    WHERE 
        r.sales_rank <= 10
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
)

SELECT 
    ti.i_item_sk,
    ti.i_item_desc,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(tr.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_sales, 0) - COALESCE(tr.total_returns, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) - COALESCE(tr.total_returns, 0) < 0 THEN 'Negative Sales'
        ELSE 'Positive Sales'
    END AS sales_status
FROM 
    TopItems ti
LEFT JOIN 
    RankedSales ts ON ti.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    SalesReturns tr ON ti.i_item_sk = tr.sr_item_sk
ORDER BY 
    net_sales DESC;

