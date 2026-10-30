
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighReturnItems AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_desc AS item_details, 
        ir.i_current_price,
        rr.total_returned,
        rr.return_count
    FROM 
        (SELECT 
            i_item_sk,
            i_item_desc, 
            i_current_price
        FROM 
            item 
        WHERE 
            i_current_price IS NOT NULL AND i_current_price > (
                SELECT AVG(i_current_price) 
                FROM item 
                WHERE i_current_price IS NOT NULL
            )
        ) ir
    JOIN RankedReturns rr ON ir.i_item_sk = rr.sr_item_sk
    WHERE rr.rn = 1
),
SeasonalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy IN (6, 7, 8))
    GROUP BY 
        ws_item_sk
)
SELECT 
    hri.item_details,
    hri.total_returned,
    hri.return_count,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales > 0 THEN (CAST(hri.total_returned AS DECIMAL) / NULLIF(ss.total_sales, 0)) * 100
        ELSE 0
    END AS return_percentage
FROM 
    HighReturnItems hri
LEFT JOIN 
    SeasonalSales ss ON hri.i_item_sk = ss.ws_item_sk
WHERE 
    hri.total_returned > (
        SELECT AVG(total_returned) 
        FROM RankedReturns 
        WHERE total_returned IS NOT NULL
    )
ORDER BY 
    return_percentage DESC
LIMIT 10;
