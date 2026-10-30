
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
FilteredReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM
        catalog_returns
    GROUP BY
        cr_item_sk
    HAVING
        SUM(cr_return_quantity) > 5
),
CombSalesReturns AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        COALESCE(fr.total_returns, 0) AS total_returns
    FROM
        RankedSales rs
    LEFT JOIN
        FilteredReturns fr ON rs.ws_item_sk = fr.cr_item_sk
)
SELECT
    cs.ws_item_sk,
    cs.total_sales,
    cs.total_returns,
    CASE 
        WHEN cs.total_returns > 0 
        THEN (cs.total_sales - cs.total_returns * (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_item_sk = cs.ws_item_sk))
        ELSE cs.total_sales
    END AS adjusted_sales,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY 
        CASE 
            WHEN cs.total_returns > 0 
            THEN (cs.total_sales - cs.total_returns * (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_item_sk = cs.ws_item_sk))
            ELSE cs.total_sales
        END DESC) AS sales_position
FROM
    CombSalesReturns cs
JOIN
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE
    i.i_current_price IS NOT NULL
    AND (cs.total_sales - cs.total_returns * 0.1) > 0
ORDER BY
    sales_position
LIMIT 20;
