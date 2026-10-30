
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
EnhancedSales AS (
    SELECT 
        S.ws_item_sk,
        COALESCE(S.total_sales, 0) AS total_sales,
        COALESCE(R.total_returns, 0) AS total_returns,
        COALESCE(R.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(R.total_returns, 0) > 0 THEN 'High Return'
            ELSE 'Low Return'
        END AS return_category
    FROM (
        SELECT 
            ws_item_sk,
            SUM(ws_quantity) AS total_sales
        FROM web_sales
        GROUP BY ws_item_sk
    ) S
    LEFT JOIN CustomerReturnStats R ON S.ws_item_sk = R.sr_customer_sk
)
SELECT 
    I.i_item_id,
    I.i_item_desc,
    E.total_sales,
    E.total_returns,
    E.total_return_amount,
    E.return_category,
    D.d_year,
    AVG(E.total_sales) OVER (PARTITION BY E.return_category) AS avg_sales_per_category
FROM EnhancedSales E
JOIN item I ON E.ws_item_sk = I.i_item_sk
JOIN date_dim D ON D.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
WHERE (E.total_sales > 100 OR E.total_returns > 5)
  AND D.d_year = 2023
ORDER BY E.total_sales DESC
LIMIT 100;
