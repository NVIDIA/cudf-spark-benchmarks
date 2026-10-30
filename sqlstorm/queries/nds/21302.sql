
WITH RankedSales AS (
    SELECT 
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk
),
MaxSales AS (
    SELECT 
        ss_item_sk,
        MAX(total_net_paid) AS max_net_paid
    FROM RankedSales
    WHERE rank = 1
    GROUP BY ss_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
FilteredReturns AS (
    SELECT 
        cr.*,
        ms.max_net_paid,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 'NO RETURNS' 
            ELSE 'HAS RETURNS' 
        END AS return_status
    FROM CustomerReturns cr
    LEFT JOIN MaxSales ms ON cr.sr_item_sk = ms.ss_item_sk
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    COALESCE(fr.return_count, 0) AS return_count,
    COALESCE(fr.total_return_amt, 0) AS return_amt,
    fr.max_net_paid,
    fr.return_status
FROM item it
LEFT JOIN FilteredReturns fr ON it.i_item_sk = fr.sr_item_sk
WHERE 
    (fr.max_net_paid IS NOT NULL AND fr.max_net_paid > 100)
    OR (fr.return_count IS NULL AND it.i_current_price < 15.00)
ORDER BY 
    it.i_item_desc,
    fr.return_count DESC NULLS LAST;
