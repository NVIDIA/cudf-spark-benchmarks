
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
AggregateReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
FinalSales AS (
    SELECT
        i.i_item_sk,
        COALESCE(MAX(rs.ws_sales_price), 0) AS max_sales_price,
        COALESCE(SUM(ar.total_returned_qty), 0) AS total_returns_qty,
        COALESCE(SUM(ar.total_returned_amt), 0) AS total_returns_amt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count
    FROM
        item i
    LEFT JOIN
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
    LEFT JOIN
        AggregateReturns ar ON i.i_item_sk = ar.sr_item_sk
    LEFT JOIN
        web_returns wr ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    WHERE
        (rs.ws_sales_price IS NULL OR rs.ws_sales_price > 20)
        AND (i.i_current_price IS NOT NULL OR i.i_wholesale_cost IS NULL)
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk > 20210101
        )
    GROUP BY
        i.i_item_sk
)
SELECT
    f.i_item_sk,
    f.max_sales_price,
    f.total_returns_qty,
    f.total_returns_amt,
    f.web_return_count,
    f.store_return_count,
    CASE 
        WHEN f.total_returns_qty > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM
    FinalSales f
WHERE
    f.max_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY
    f.total_returns_amt DESC, f.max_sales_price ASC;
