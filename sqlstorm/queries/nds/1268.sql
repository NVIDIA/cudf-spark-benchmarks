
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM
        web_returns wr
    JOIN
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        wr.wr_item_sk
)
SELECT
    i.i_item_id,
    sd.total_quantity,
    sd.total_sales,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    (sd.total_sales - COALESCE(cr.total_returned_amt, 0)) AS net_revenue,
    CASE 
        WHEN sd.total_quantity > 1000 THEN 'High'
        WHEN sd.total_quantity BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    SalesData sd
LEFT JOIN
    CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
JOIN
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE
    sd.sales_rank = 1
ORDER BY
    net_revenue DESC
LIMIT 10;

