
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM
        web_sales ws
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM
        SalesData sd
    WHERE
        sd.rank <= 10
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returned, 0) AS total_returns,
    COALESCE(cr.avg_return_amount, 0) AS avg_return_value,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) = 0 THEN 0
        ELSE (COALESCE(cr.total_returned, 0) / NULLIF(COALESCE(ts.total_quantity, 0), 0)) * 100 
    END AS return_percentage
FROM
    item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE
    (COALESCE(ts.total_sales, 0) > 500 OR COALESCE(cr.total_returned, 0) > 0)
ORDER BY
    return_percentage DESC;
