
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
ReturnCTE AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr_item_sk
),
PerformanceData AS (
    SELECT 
        s.ws_item_sk AS item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
        (s.total_quantity - COALESCE(r.total_return_quantity, 0)) AS net_quantity
    FROM 
        SalesCTE s
    LEFT JOIN 
        ReturnCTE r ON s.ws_item_sk = r.cr_item_sk
)
SELECT 
    p.i_item_id,
    p.i_item_desc,
    pd.total_quantity,
    pd.total_sales,
    pd.total_return_quantity,
    pd.total_return_amount,
    pd.net_sales,
    pd.net_quantity
FROM 
    PerformanceData pd
JOIN 
    item p ON pd.item_sk = p.i_item_sk
WHERE 
    pd.net_sales > 1000
ORDER BY 
    pd.net_sales DESC
LIMIT 10;
