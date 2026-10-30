
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sales_price) AS max_price,
        MIN(ws_sales_price) AS min_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rs.sales_rank,
        rs.order_count,
        CASE 
            WHEN rs.max_price IS NOT NULL AND rs.min_price IS NOT NULL THEN (rs.max_price - rs.min_price) / NULLIF(rs.min_price, 0)
            ELSE NULL 
        END AS price_variance
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    fs.ws_item_sk,
    fs.total_sales,
    fs.order_count,
    fs.price_variance,
    CASE 
        WHEN fs.price_variance IS NOT NULL AND fs.price_variance > 1 THEN 'High Variance'
        WHEN fs.price_variance IS NOT NULL AND fs.price_variance <= 1 THEN 'Low Variance'
        ELSE 'No Price Data'
    END AS variance_category,
    COALESCE((
        SELECT AVG(ss_net_profit)
        FROM store_sales ss
        WHERE ss.ss_item_sk = fs.ws_item_sk 
          AND ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ), 0) AS avg_store_profit
FROM 
    FilteredSales fs
LEFT JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price < (SELECT AVG(i_current_price) FROM item)
ORDER BY 
    fs.total_sales DESC
LIMIT 100;
