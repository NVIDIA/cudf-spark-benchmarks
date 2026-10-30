
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
store_return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
filtered_items AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(r.total_quantity, 0) AS total_quantity,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(s.total_returns, 0) AS total_returns,
        COALESCE(s.total_return_amount, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN ranked_sales r ON i.i_item_sk = r.ws_item_sk
    LEFT JOIN store_return_summary s ON i.i_item_sk = s.sr_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
        AND (i.i_item_desc LIKE '%special%' OR i.i_item_desc LIKE '%unique%')
)
SELECT 
    f.i_item_sk,
    f.i_item_desc,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_return_amount,
    CASE 
        WHEN f.total_sales > 10000 THEN 'High Sales'
        WHEN f.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    filtered_items f
WHERE 
    (f.total_quantity IS NOT NULL AND f.total_quantity > 0)
    OR (f.total_returns IS NOT NULL AND f.total_returns > 0)
ORDER BY 
    sales_category DESC, 
    f.total_sales DESC
LIMIT 50;

