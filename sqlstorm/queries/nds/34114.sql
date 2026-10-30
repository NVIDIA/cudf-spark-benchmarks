
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
Customer_Returns AS (
    SELECT 
        cr_item_sk, 
        COUNT(*) AS total_returns, 
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns 
    GROUP BY 
        cr_item_sk
),
Top_Items AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_id, 
        COALESCE(SALES.total_quantity, 0) AS total_quantity,
        COALESCE(SALES.total_sales, 0) AS total_sales,
        COALESCE(RETURNS.total_returns, 0) AS total_returns,
        COALESCE(RETURNS.total_return_amount, 0) AS total_return_amount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SALES.total_sales, 0) DESC) AS rank
    FROM 
        item
    LEFT JOIN 
        Sales_CTE SALES ON item.i_item_sk = SALES.ws_item_sk
    LEFT JOIN 
        Customer_Returns RETURNS ON item.i_item_sk = RETURNS.cr_item_sk
)
SELECT 
    t.i_item_id AS item_id, 
    t.total_quantity, 
    t.total_sales, 
    t.total_returns, 
    t.total_return_amount
FROM 
    Top_Items t
WHERE 
    (t.total_sales / NULLIF(t.total_quantity, 0)) > 20 
    AND t.rank <= 10
ORDER BY 
    t.rank;
