
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returns,
        rr.total_return_amt,
        ri.i_item_desc,
        ri.i_current_price,
        COALESCE(ri.i_current_price * 0.9, 0) AS discounted_price,
        CASE 
            WHEN rr.total_return_amt IS NULL THEN 'No Returns'
            WHEN rr.total_return_amt < 1000 THEN 'Low Returns'
            ELSE 'High Returns' 
        END AS return_category
    FROM 
        RankedReturns rr
    LEFT JOIN 
        item ri ON rr.sr_item_sk = ri.i_item_sk
    WHERE 
        rr.rank <= 5
),
ReturnAnalysis AS (
    SELECT 
        t.return_category,
        COUNT(*) AS item_count,
        AVG(total_returns) AS avg_returns,
        SUM(total_return_amt) AS total_amt
    FROM 
        TopReturns t
    GROUP BY 
        t.return_category
)
SELECT 
    ra.return_category,
    ra.item_count,
    ra.avg_returns,
    ra.total_amt,
    CASE 
        WHEN ra.total_amt > 5000 THEN 'Significant Returns'
        ELSE 'Minor Returns'
    END AS return_significance,
    ROW_NUMBER() OVER (ORDER BY ra.total_amt DESC) AS return_rank
FROM 
    ReturnAnalysis ra
UNION ALL
SELECT 
    'Summary' AS return_category,
    COUNT(DISTINCT sr_item_sk) AS item_count,
    AVG(total_returns) AS avg_returns,
    SUM(total_return_amt) AS total_amt,
    'Overall' AS return_significance,
    NULL AS return_rank
FROM 
    TopReturns;
