
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
ItemReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM
        web_returns wr
    JOIN
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_net_paid,
        COALESCE(ir.total_returns, 0) AS total_returns,
        r.total_sales - COALESCE(ir.total_returns, 0) AS net_sales,
        r.sales_rank
    FROM
        RankedSales r
    LEFT JOIN
        ItemReturns ir ON r.ws_item_sk = ir.wr_item_sk
)
SELECT 
    i.i_item_id,
    SUM(swr.net_sales) AS total_net_sales,
    SUM(swr.total_returns) AS total_returns,
    COUNT(DISTINCT swr.ws_order_number) AS total_orders,
    AVG(swr.ws_quantity) AS avg_quantity_per_order,
    MAX(swr.sales_rank) AS max_sales_rank
FROM 
    SalesWithReturns swr
JOIN 
    item i ON swr.ws_item_sk = i.i_item_sk
WHERE 
    swr.net_sales > 0
GROUP BY 
    i.i_item_id
HAVING 
    SUM(swr.net_sales) > 1000
ORDER BY 
    total_net_sales DESC
LIMIT 10;
