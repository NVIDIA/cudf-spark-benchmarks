
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sales_price IS NOT NULL
),
AggregateReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS TotalReturns,
        COUNT(DISTINCT cr.cr_order_number) AS UniqueReturns,
        AVG(cr.cr_return_amount) AS AvgReturnAmount
    FROM
        catalog_returns cr
    WHERE
        cr.cr_return_quantity > 0
    GROUP BY
        cr.cr_item_sk
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    COALESCE(rs.TotalSales, 0) AS TotalSales,
    COALESCE(ar.UniqueReturns, 0) AS UniqueReturns,
    ar.TotalReturns,
    ar.AvgReturnAmount,
    CASE 
        WHEN ar.TotalReturns IS NULL THEN 'No Returns'
        WHEN ar.TotalReturns > 100 THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS ReturnCategory
FROM 
    item
LEFT JOIN (
    SELECT
        r.ws_item_sk,
        SUM(r.ws_sales_price) AS TotalSales
    FROM 
        web_sales r
    JOIN RankedSales rs ON r.ws_item_sk = rs.ws_item_sk AND rs.SalesRank = 1
    GROUP BY 
        r.ws_item_sk
) AS rs ON item.i_item_sk = rs.ws_item_sk
LEFT JOIN AggregateReturns ar ON item.i_item_sk = ar.cr_item_sk
WHERE
    item.i_current_price > (SELECT AVG(i_current_price) FROM item)
ORDER BY
    TotalSales DESC,
    TotalReturns ASC NULLS LAST
LIMIT 50;
