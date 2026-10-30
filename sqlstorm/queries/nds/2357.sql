
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rank_quantity
    FROM
        web_sales
),
FilteredSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(rs1.rank_price, 0) AS rank_price,
        COALESCE(rs2.rank_quantity, 0) AS rank_quantity
    FROM
        web_sales ws
    LEFT JOIN RankedSales rs1 ON ws.ws_item_sk = rs1.ws_item_sk AND rs1.rank_price <= 3
    LEFT JOIN RankedSales rs2 ON ws.ws_item_sk = rs2.ws_item_sk AND rs2.rank_quantity <= 3
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(fs.ws_sales_price * fs.ws_quantity) AS total_sales,
    SUM(fs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT fs.ws_item_sk) AS distinct_sales,
    CASE 
        WHEN SUM(fs.ws_quantity) > 0 THEN AVG(fs.ws_sales_price) 
        ELSE NULL 
    END AS avg_price,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers
FROM 
    FilteredSales fs
JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc
HAVING 
    SUM(fs.ws_sales_price * fs.ws_quantity) > 1000 
    AND (SUM(fs.ws_quantity) IS NULL OR SUM(fs.ws_quantity) > 50)
ORDER BY 
    total_sales DESC
LIMIT 10;
