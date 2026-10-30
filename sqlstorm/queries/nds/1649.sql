
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_returning_customers
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
BestSellingItems AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.distinct_returning_customers, 0) AS distinct_returning_customers
    FROM
        RankedSales r
    LEFT JOIN CustomerReturns cr ON r.ws_item_sk = cr.wr_item_sk
    WHERE
        r.SalesRank = 1
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    b.ws_net_profit,
    b.total_returned,
    b.distinct_returning_customers,
    'Profitability: ' || ROUND((b.ws_net_profit - (COALESCE(b.total_returned, 0) * i.i_current_price)), 2) AS Profitability_Status
FROM
    item i
JOIN BestSellingItems b ON i.i_item_sk = b.ws_item_sk
WHERE
    (b.total_returned > 0 OR b.distinct_returning_customers > 0)
ORDER BY
    b.ws_net_profit DESC
LIMIT 10;
