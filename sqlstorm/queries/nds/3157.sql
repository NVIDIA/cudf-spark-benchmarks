
WITH RankSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
SalesReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
CombinedReturns AS (
    SELECT
        coalesce(wr.wr_item_sk, sr.sr_item_sk) AS item_sk,
        COALESCE(wr.total_return_amt, 0) + COALESCE(sr.total_return_amt, 0) AS total_combined_returns
    FROM
        SalesReturns wr
    FULL OUTER JOIN
        TotalReturns sr ON wr.wr_item_sk = sr.sr_item_sk
),
FinalSales AS (
    SELECT
        r.ws_item_sk,
        r.total_sales,
        COALESCE(c.total_combined_returns, 0) AS total_combined_returns,
        r.total_sales - COALESCE(c.total_combined_returns, 0) AS net_sales
    FROM
        RankSales r
    LEFT JOIN
        CombinedReturns c ON r.ws_item_sk = c.item_sk
    WHERE
        r.sales_rank <= 10
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    fs.total_sales,
    fs.total_combined_returns,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales > 10000 THEN 'High Performer'
        WHEN fs.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM
    FinalSales fs
JOIN
    item i ON fs.ws_item_sk = i.i_item_sk
ORDER BY
    fs.net_sales DESC;
