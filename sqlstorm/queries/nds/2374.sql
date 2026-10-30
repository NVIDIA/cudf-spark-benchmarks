
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
TopProducts AS (
    SELECT 
        R.ws_item_sk, 
        R.total_sales, 
        C.total_returns
    FROM 
        RankedSales R
    LEFT JOIN 
        CustomerReturns C ON R.ws_item_sk = C.cr_item_sk
    WHERE 
        R.sales_rank <= 10
)
SELECT 
    P.i_item_id, 
    P.i_item_desc, 
    COALESCE(T.total_sales, 0) AS net_sales,
    COALESCE(T.total_returns, 0) AS net_returns,
    CASE 
        WHEN COALESCE(T.total_sales, 0) = 0 THEN 'No Sales'
        ELSE CAST((COALESCE(T.total_sales, 0) - COALESCE(T.total_returns, 0)) AS VARCHAR(20))
    END AS net_profit,
    CASE 
        WHEN T.total_sales IS NULL OR T.total_returns IS NULL THEN 'N/A' 
        ELSE CAST((COALESCE(T.total_sales, 0) - COALESCE(T.total_returns, 0)) / NULLIF(T.total_sales, 0) * 100 AS VARCHAR(20)) || '%' 
    END AS return_rate
FROM 
    item P
LEFT JOIN 
    TopProducts T ON P.i_item_sk = T.ws_item_sk
ORDER BY 
    net_sales DESC;
