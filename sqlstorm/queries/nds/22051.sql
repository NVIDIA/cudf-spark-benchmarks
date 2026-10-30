
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
BestSellingItems AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(tr.total_return_quantity), 0) AS total_returned,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS gross_sales
    FROM 
        item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        TotalReturns tr ON item.i_item_sk = tr.sr_item_sk
    WHERE 
        item.i_rec_start_date < DATE '2002-10-01' 
        AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date > DATE '2002-10-01')
    GROUP BY 
        item.i_item_sk, 
        item.i_item_id
),
HighMarginItems AS (
    SELECT 
        bi.i_item_sk,
        (bi.gross_sales / NULLIF(SUM(ss.ss_wholesale_cost), 0)) AS margin_ratio
    FROM 
        BestSellingItems bi
    JOIN 
        store_sales ss ON bi.i_item_sk = ss.ss_item_sk
    GROUP BY 
        bi.i_item_sk, bi.gross_sales
)
SELECT 
    i.i_item_id,
    COALESCE(m.margin_ratio, 0) AS margin_ratio,
    r.SalesRank,
    CASE 
        WHEN COALESCE(m.margin_ratio, 0) > 2 THEN 'High Margin'
        WHEN COALESCE(m.margin_ratio, 0) BETWEEN 1 AND 2 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS margin_category
FROM 
    item i
LEFT JOIN 
    HighMarginItems m ON i.i_item_sk = m.i_item_sk
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.SalesRank = 1
WHERE 
    i.i_item_sk IN (
        SELECT DISTINCT ws_item_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk > (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = DATE '2002-10-01' - INTERVAL '30 DAY'
        )
    )
ORDER BY 
    margin_ratio DESC NULLS LAST, 
    i.i_item_id 
LIMIT 100;
