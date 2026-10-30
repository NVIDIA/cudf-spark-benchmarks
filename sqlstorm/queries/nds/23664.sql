
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_customer_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS ReturnRank
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
),
TotalSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
HighReturnItems AS (
    SELECT
        rr.sr_item_sk,
        rr.returned_date AS return_date,
        rr.return_quantity,
        ts.total_sold,
        ts.total_profit,
        (CAST(rr.return_quantity AS decimal) / NULLIF(ts.total_sold, 0)) AS return_rate
    FROM
        (SELECT
            sr_item_sk,
            MAX(sr_returned_date_sk) AS returned_date,
            SUM(sr_return_quantity) AS return_quantity
         FROM
            RankedReturns
         WHERE
            ReturnRank = 1
         GROUP BY
            sr_item_sk) rr
    JOIN
        TotalSales ts ON rr.sr_item_sk = ts.ws_item_sk
    WHERE
        (CAST(rr.return_quantity AS decimal) / NULLIF(ts.total_sold, 0)) > 0.5
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(s.s_store_name, 'Unknown') AS store_name,
        COALESCE(c.cc_name, 'Unknown') AS call_center_name,
        h.return_rate
    FROM
        item i
    LEFT JOIN
        store s ON i.i_item_sk = s.s_store_sk
    LEFT JOIN
        call_center c ON i.i_item_sk = c.cc_call_center_sk
    JOIN
        HighReturnItems h ON i.i_item_sk = h.sr_item_sk
)
SELECT
    id.i_item_id,
    id.i_item_desc,
    id.store_name,
    id.call_center_name,
    COALESCE(id.return_rate, 0) AS return_rate,
    CASE
        WHEN id.return_rate > 0.75 THEN 'High Risk'
        WHEN id.return_rate BETWEEN 0.5 AND 0.75 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM
    ItemDetails id
ORDER BY
    id.return_rate DESC,
    id.i_item_desc ASC
LIMIT 100;
