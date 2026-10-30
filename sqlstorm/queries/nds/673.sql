
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS price_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (6, 7)
    )
),
ItemReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(COALESCE(r.cs_quantity, 0)) AS total_sales,
        COALESCE(SUM(ir.total_returned), 0) AS total_returns,
        SUM(COALESCE(r.cs_quantity, 0)) - COALESCE(SUM(ir.total_returned), 0) AS net_sales,
        AVG(r.price_rank) AS avg_price_rank
    FROM RankedSales r
    JOIN item i ON r.cs_item_sk = i.i_item_sk
    LEFT JOIN ItemReturns ir ON r.cs_item_sk = ir.cr_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.total_sales,
    s.total_returns,
    s.net_sales,
    s.avg_price_rank,
    CASE 
        WHEN s.net_sales > 1000 THEN 'High Performer'
        WHEN s.net_sales BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesSummary s
WHERE s.net_sales IS NOT NULL
ORDER BY s.net_sales DESC;
