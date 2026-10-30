
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) 
                              FROM date_dim 
                              WHERE d_date BETWEEN CURRENT_DATE - INTERVAL '1 day' AND CURRENT_DATE)
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        SUM(rs.ws_quantity) AS total_quantity,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items
    FROM RankedSales rs
    WHERE rs.rn <= 10
    GROUP BY rs.ws_item_sk
)
SELECT 
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 1000 THEN 'High Sales'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    i.i_item_id,
    i.i_item_desc,
    ss.total_sales,
    ss.total_quantity
FROM SalesSummary ss
LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
WHERE ss.total_quantity IS NOT NULL
AND (i.i_item_desc LIKE '%special%' OR ss.total_sales IS NOT NULL)
ORDER BY ss.total_sales DESC
LIMIT 50;
