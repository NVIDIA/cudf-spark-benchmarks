WITH
    RankedReturns AS (
        SELECT
            sr_returned_date_sk,
            sr_item_sk,
            sr_return_quantity,
            ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
        FROM
            store_returns
    ),
    
    RecentReturns AS (
        SELECT
            rr.sr_item_sk,
            SUM(rr.sr_return_quantity) AS total_returned_quantity
        FROM
            RankedReturns rr
        WHERE
            rr.rn <= 5 
        GROUP BY
            rr.sr_item_sk
    ),
    
    ItemSales AS (
        SELECT
            wsi.ws_item_sk,
            SUM(wsi.ws_quantity) AS total_sold_quantity,
            SUM(wsi.ws_net_profit) AS total_net_profit
        FROM
            web_sales wsi
        GROUP BY
            wsi.ws_item_sk
    ),
    
    SalesAndReturns AS (
        SELECT
            i.i_item_id,
            COALESCE(isales.total_sold_quantity, 0) AS total_sold_quantity,
            COALESCE(rreturns.total_returned_quantity, 0) AS total_returned_quantity,
            CASE 
                WHEN COALESCE(isales.total_sold_quantity, 0) > 0 THEN 
                    (COALESCE(rreturns.total_returned_quantity, 0) * 1.0 / COALESCE(isales.total_sold_quantity, 0))
                ELSE 
                    NULL
            END AS return_ratio
        FROM
            item i
        LEFT JOIN
            ItemSales isales ON i.i_item_sk = isales.ws_item_sk
        LEFT JOIN
            RecentReturns rreturns ON i.i_item_sk = rreturns.sr_item_sk
    )

SELECT
    sar.i_item_id,
    sar.total_sold_quantity,
    sar.total_returned_quantity,
    sar.return_ratio,
    CASE 
        WHEN sar.return_ratio IS NULL THEN 'No Sales'
        WHEN sar.return_ratio > 0.5 THEN 'High Return Rate'
        WHEN sar.return_ratio BETWEEN 0.2 AND 0.5 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM
    SalesAndReturns sar
WHERE
    sar.return_ratio IS NOT NULL
ORDER BY
    sar.return_ratio DESC
LIMIT 10;