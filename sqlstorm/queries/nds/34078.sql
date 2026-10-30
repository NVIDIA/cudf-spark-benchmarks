
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
BestSellingItems AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0.00) AS total_return_amount,
        CASE 
            WHEN COALESCE(r.total_returns, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned' 
        END AS return_status
    FROM SalesCTE s
    LEFT JOIN CustomerReturns r ON s.ws_item_sk = r.sr_item_sk
    WHERE s.rank <= 10
)
SELECT 
    i.i_item_desc,
    b.total_quantity,
    b.total_sales,
    b.total_returns,
    b.total_return_amount,
    b.return_status,
    ROW_NUMBER() OVER (ORDER BY b.total_sales DESC) AS sales_rank
FROM BestSellingItems b
JOIN item i ON b.ws_item_sk = i.i_item_sk
WHERE b.total_sales > 1000
ORDER BY b.total_sales DESC;
