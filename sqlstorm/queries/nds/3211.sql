
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
HighVolumeSales AS (
    SELECT 
        ws_item_sk,
        total_quantity
    FROM RankedSales
    WHERE rank <= 10
),
ReturnDetails AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(hv.total_quantity, 0) AS total_web_sales,
        COALESCE(rd.total_return_quantity, 0) AS total_web_returns,
        COALESCE(rd.total_return_amt, 0) AS total_return_amount,
        COALESCE((COALESCE(hv.total_quantity, 0) - COALESCE(rd.total_return_quantity, 0)), 0) AS net_sales
    FROM item i
    LEFT JOIN HighVolumeSales hv ON i.i_item_sk = hv.ws_item_sk
    LEFT JOIN ReturnDetails rd ON i.i_item_sk = rd.wr_item_sk
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_web_sales,
    f.total_web_returns,
    f.total_return_amount,
    CASE 
        WHEN f.net_sales >= 100 THEN 'High Volume'
        WHEN f.net_sales BETWEEN 50 AND 99 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM FinalReport f
WHERE f.total_web_sales > 0
ORDER BY f.net_sales DESC;
