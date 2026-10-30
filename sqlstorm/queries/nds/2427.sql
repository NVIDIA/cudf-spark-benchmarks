
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_sold_date_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rank_per_item
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_net_paid,
        cr.total_returns,
        cr.total_return_amt,
        CASE 
            WHEN cr.total_returns IS NULL THEN 0
            ELSE cr.total_returns
        END AS adjusted_returns,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 0
            ELSE cr.total_return_amt
        END AS adjusted_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.cs_item_sk = cr.sr_item_sk
    WHERE 
        rs.rank_per_item <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_paid,
    tsi.adjusted_returns,
    tsi.adjusted_return_amt,
    CASE 
        WHEN tsi.adjusted_returns = 0 THEN 'No Returns'
        WHEN tsi.adjusted_returns < 5 THEN 'Few Returns'
        ELSE 'Many Returns'
    END AS return_category
FROM 
    TopSellingItems tsi
JOIN 
    item ti ON tsi.cs_item_sk = ti.i_item_sk
ORDER BY 
    tsi.total_net_paid DESC;
