
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
PastReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2022
        )
    GROUP BY 
        cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_sold,
    COALESCE(rs.total_sales, 0.00) AS total_sales_income,
    COALESCE(pr.total_returns, 0) AS total_returns,
    COALESCE(pr.total_return_amount, 0.00) AS total_return_income,
    (COALESCE(rs.total_sales, 0.00) - COALESCE(pr.total_return_amount, 0.00)) AS net_income,
    CASE 
        WHEN COALESCE(pr.total_returns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned' 
    END AS return_status
FROM 
    item i
LEFT JOIN 
    RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    PastReturns pr ON i.i_item_sk = pr.cr_item_sk
WHERE 
    (COALESCE(rs.total_sales, 0.00) > 500 OR COALESCE(pr.total_returns, 0) > 0)
ORDER BY 
    net_income DESC
LIMIT 10;
