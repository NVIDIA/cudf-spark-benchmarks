
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 50
),
AggregatedReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(ars.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ars.total_return_amt, 0) AS total_return_amt,
        COALESCE(rks.sales_rank, 0) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        AggregatedReturns ars ON i.i_item_sk = ars.sr_item_sk
    LEFT JOIN 
        RankedSales rks ON i.i_item_sk = rks.ws_item_sk AND rks.sales_rank = 1
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.total_return_quantity,
    id.total_return_amt,
    CASE 
        WHEN id.total_return_quantity > 10 THEN 'High Return'
        WHEN id.total_return_quantity BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return' 
    END AS return_category,
    CONCAT(ROUND((id.total_return_amt / NULLIF(SUM(id.total_return_amt) OVER (), 0) * 100), 2), '%') AS return_percentage
FROM 
    ItemDetails id
WHERE 
    id.sales_rank = 1
ORDER BY 
    id.total_return_amt DESC;
