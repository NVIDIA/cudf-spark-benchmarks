
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_item_sk
),
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_value 
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY wr_item_sk
),
sales_and_returns AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_value, 0) AS total_return_value,
        sd.total_quantity,
        CASE 
            WHEN COALESCE(rd.total_returns, 0) = 0 THEN NULL
            ELSE (COALESCE(rd.total_return_value, 0) / COALESCE(sd.total_sales, 1)) * 100
        END AS return_percentage
    FROM sales_data sd
    LEFT JOIN return_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    sa.ws_item_sk,
    sa.total_sales,
    sa.total_returns,
    sa.return_percentage,
    ROW_NUMBER() OVER (ORDER BY sa.return_percentage DESC NULLS LAST) AS return_rank,
    (SELECT AVG(total_sales) FROM sales_data) AS avg_sales,
    (SELECT COUNT(*) FROM store) AS total_stores
FROM sales_and_returns sa
WHERE sa.return_percentage < 50
  AND sa.total_sales > (SELECT AVG(total_sales) FROM sales_data)
ORDER BY return_rank
LIMIT 10;
