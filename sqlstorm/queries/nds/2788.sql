
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= DATE '2002-10-01' AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2002-10-01')
),
LatestSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.rank = 1
),
AggregateSales AS (
    SELECT 
        i.i_category,
        COUNT(DISTINCT ls.ws_item_sk) AS item_count,
        SUM(ls.total_quantity) AS total_units_sold,
        SUM(ls.total_sales) AS total_revenue,
        CASE 
            WHEN SUM(ls.total_sales) IS NULL THEN 0 
            ELSE SUM(ls.total_sales) / NULLIF(SUM(ls.total_quantity), 0) 
        END AS avg_selling_price
    FROM LatestSales ls
    JOIN item i ON ls.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT 
    a.i_category,
    a.item_count,
    a.total_units_sold,
    a.total_revenue,
    a.avg_selling_price,
    r.r_reason_desc
FROM AggregateSales a
LEFT JOIN reason r ON r.r_reason_sk = 1 AND a.total_revenue > 100000
WHERE a.total_revenue IS NOT NULL OR a.item_count > 0
ORDER BY a.total_revenue DESC
LIMIT 10;
