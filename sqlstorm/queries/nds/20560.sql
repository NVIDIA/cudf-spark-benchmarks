
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank_per_item
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk, 
        rr.total_returns, 
        rr.total_return_amt,
        RANK() OVER (ORDER BY rr.total_return_amt DESC) AS overall_rank
    FROM 
        RankedReturns rr
    WHERE 
        rr.total_returns > 0
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE((
            SELECT SUM(ws_quantity) 
            FROM web_sales 
            WHERE ws_item_sk = i.i_item_sk
            GROUP BY ws_item_sk
        ), 0) AS total_web_sales,
        COALESCE((
            SELECT SUM(cs_quantity) 
            FROM catalog_sales 
            WHERE cs_item_sk = i.i_item_sk
            GROUP BY cs_item_sk
        ), 0) AS total_catalog_sales,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Unknown Price'
            WHEN i.i_current_price < 0 THEN 'Negative Price'
            ELSE 'Valid Price'
        END AS price_status
    FROM 
        item i
)
SELECT 
    it.i_item_sk,
    it.i_item_desc,
    it.i_current_price,
    it.total_web_sales,
    it.total_catalog_sales,
    tr.total_returns,
    tr.total_return_amt,
    tr.overall_rank,
    CASE 
        WHEN tr.overall_rank = 1 THEN 'Top Returned Item'
        ELSE 'Regular Item'
    END AS item_status,
    ROW_NUMBER() OVER (PARTITION BY it.price_status ORDER BY it.i_current_price DESC) AS price_rank
FROM 
    ItemDetails it
LEFT JOIN 
    TopReturnedItems tr ON it.i_item_sk = tr.sr_item_sk
WHERE 
    it.total_web_sales > 0 OR it.total_catalog_sales > 0
ORDER BY 
    tr.total_return_amt DESC NULLS LAST, 
    it.i_current_price DESC;
