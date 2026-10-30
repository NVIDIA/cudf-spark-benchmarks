
WITH RecursiveSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_ext_sales_price) as total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
ReturnInfo AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) as total_returns
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
SalesWithReturns AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        COALESCE(ri.total_returns, 0) AS total_returns,
        (rs.total_sales - COALESCE(ri.total_returns, 0) * 100) AS net_sales
    FROM
        RecursiveSales rs
    LEFT JOIN
        ReturnInfo ri ON rs.ws_item_sk = ri.wr_item_sk
),
RankedSales AS (
    SELECT
        swr.ws_item_sk,
        swr.total_quantity,
        swr.total_returns,
        swr.net_sales,
        RANK() OVER (ORDER BY swr.net_sales DESC) as sales_rank
    FROM
        SalesWithReturns swr
)

SELECT
    s.i_item_id,
    s.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.total_returns, 0) AS total_returns,
    rs.net_sales,
    rs.sales_rank
FROM
    item s
LEFT JOIN
    RankedSales rs ON s.i_item_sk = rs.ws_item_sk
WHERE
    (rs.sales_rank <= 10 OR rs.sales_rank IS NULL)
    AND s.i_current_price > 20
ORDER BY
    net_sales DESC;
