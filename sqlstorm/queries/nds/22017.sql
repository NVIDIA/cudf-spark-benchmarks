
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        MAX(sr_return_quantity) AS max_return_quantity,
        MIN(sr_return_quantity) AS min_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount,
        AVG(wr_return_quantity) AS avg_web_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_item_sk
),
CombinedReturns AS (
    SELECT 
        cr.sr_returned_date_sk,
        cr.sr_item_sk,
        COALESCE(cr.total_returns, 0) AS total_store_returns,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        (COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_web_return_amount, 0)) AS combined_total_return_amount,
        (COALESCE(cr.total_returns, 0) - COALESCE(wr.total_web_returns, 0)) AS store_net_returns
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_item_sk = wr.wr_item_sk AND cr.sr_returned_date_sk = wr.wr_returned_date_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_item_desc,
        SUM(CASE 
            WHEN cr.combined_total_return_amount IS NULL THEN 0 
            ELSE cr.combined_total_return_amount END) AS total_combined_returns,
        COUNT(DISTINCT cr.sr_returned_date_sk) AS return_days
    FROM 
        item 
    LEFT JOIN 
        CombinedReturns cr ON item.i_item_sk = cr.sr_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id, item.i_item_desc
    HAVING 
        SUM(CASE 
            WHEN cr.combined_total_return_amount IS NULL THEN 0 
            ELSE cr.combined_total_return_amount END) > 0
    ORDER BY 
        total_combined_returns DESC
)
SELECT 
    ti.i_item_sk,
    ti.i_item_id,
    COALESCE(ti.return_days, 0) AS returnable_days,
    ti.total_combined_returns,
    RANK() OVER (ORDER BY ti.total_combined_returns DESC) AS rank
FROM 
    TopItems ti
WHERE 
    ti.total_combined_returns > (SELECT AVG(total_combined_returns) FROM TopItems) + 100
UNION ALL
SELECT 
    -1 AS i_item_sk, 
    'Total' AS i_item_id, 
    NULL AS returnable_days, 
    SUM(total_combined_returns) AS total_combined_returns,
    NULL AS rank 
FROM 
    TopItems
ORDER BY 
    total_combined_returns DESC;
