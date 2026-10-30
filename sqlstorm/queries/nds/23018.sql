
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
),
FilteredItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        r.total_net_paid,
        c.total_returns,
        COALESCE(c.total_return_amt, 0) AS adjusted_return_amt,
        (COALESCE(c.total_return_amt, 0) - COALESCE(c.total_returns, 0)) AS net_return_adjustment
    FROM 
        item i
    LEFT JOIN 
        RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.sales_rank = 1
    LEFT JOIN 
        CustomerReturns c ON i.i_item_sk = c.sr_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_rec_end_date IS NULL)
          AND (COALESCE(c.total_return_amt, 0) - COALESCE(c.total_returns, 0) > 0 OR COALESCE(c.total_return_amt, 0) IS NULL)
),
FinalSummary AS (
    SELECT 
        f.i_item_desc,
        f.total_net_paid,
        f.total_returns,
        f.adjusted_return_amt,
        f.net_return_adjustment,
        CASE 
            WHEN f.total_net_paid IS NULL THEN 'No Sales'
            WHEN f.total_net_paid > 500 THEN 'High Revenue Item'
            WHEN f.total_net_paid BETWEEN 100 AND 500 THEN 'Medium Revenue Item'
            ELSE 'Low Revenue Item'
        END AS revenue_category
    FROM 
        FilteredItems f
)
SELECT 
    revenue_category,
    COUNT(*) AS item_count,
    SUM(total_net_paid) AS total_revenue,
    AVG(adjusted_return_amt) AS avg_adjusted_return
FROM 
    FinalSummary
GROUP BY 
    revenue_category
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_revenue DESC;
