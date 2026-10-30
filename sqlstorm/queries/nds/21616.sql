
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_id,
        i.i_product_name,
        rr.total_returned
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.rnk <= 5
),
CurrentDate AS (
    SELECT 
        CAST('2002-10-01' AS DATE) AS today
),
SalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sold 
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk = (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d
            WHERE 
                d.d_date = (SELECT today FROM CurrentDate)
        )
    GROUP BY 
        ss.ss_item_sk
),
SalesVsReturns AS (
    SELECT 
        hri.i_item_id,
        hri.i_product_name,
        COALESCE(sd.total_sold, 0) AS total_sold,
        hri.total_returned
    FROM 
        HighReturnItems hri
    LEFT JOIN 
        SalesData sd ON hri.sr_item_sk = sd.ss_item_sk
),
FinalResults AS (
    SELECT 
        f.i_item_id,
        f.i_product_name,
        f.total_sold,
        f.total_returned,
        CASE 
            WHEN f.total_returned = 0 THEN 'No Returns'
            ELSE CAST((f.total_returned / NULLIF(f.total_sold, 0)) * 100 AS DECIMAL(5,2)) || '%' 
        END AS return_rate
    FROM 
        SalesVsReturns f
)
SELECT 
    fr.i_item_id,
    fr.i_product_name,
    fr.total_sold,
    fr.total_returned,
    fr.return_rate
FROM 
    FinalResults fr
WHERE 
    fr.return_rate IS NOT NULL
ORDER BY 
    fr.return_rate DESC, 
    fr.total_sold DESC;
