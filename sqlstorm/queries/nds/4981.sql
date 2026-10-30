
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
HighDemandItems AS (
    SELECT
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_sold
    FROM 
        RankedSales r
    WHERE
        r.rank <= 5
    GROUP BY
        r.ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(hdi.total_sold, 0) AS total_sold,
    COALESCE(tr.total_return_quantity, 0) AS total_returned,
    COALESCE(tr.total_return_amt, 0.00) AS total_return_amount,
    i.i_current_price,
    (COALESCE(hdi.total_sold, 0) - COALESCE(tr.total_return_quantity, 0)) AS net_sales
FROM 
    item i
LEFT JOIN 
    HighDemandItems hdi ON i.i_item_sk = hdi.ws_item_sk
LEFT JOIN 
    TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
WHERE
    (i.i_current_price > 50 OR i.i_item_desc LIKE '%premium%')
ORDER BY
    net_sales DESC;
