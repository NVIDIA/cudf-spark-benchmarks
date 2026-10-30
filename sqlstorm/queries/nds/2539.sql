
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        sd.total_net_paid - COALESCE(cr.total_return_amount, 0) AS net_revenue
    FROM SalesData sd
    LEFT JOIN CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
),
RankedSales AS (
    SELECT 
        swr.ws_item_sk,
        swr.total_quantity,
        swr.total_net_paid,
        swr.total_returned_quantity,
        swr.total_return_amount,
        swr.net_revenue,
        RANK() OVER (ORDER BY swr.net_revenue DESC) AS revenue_rank
    FROM SalesWithReturns swr
)
SELECT 
    ws_item_sk AS r_item_sk,
    total_quantity,
    total_net_paid,
    total_returned_quantity,
    total_return_amount,
    net_revenue,
    revenue_rank
FROM RankedSales
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
