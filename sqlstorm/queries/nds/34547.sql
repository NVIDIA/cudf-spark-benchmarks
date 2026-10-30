
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as order_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy IN (4, 5)
    )
),
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM sales_data sd
    WHERE sd.order_rank <= 10
    GROUP BY sd.ws_item_sk
),
returned_sales AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    GROUP BY cr_item_sk
),
final_sales AS (
    SELECT 
        a.ws_item_sk,
        a.total_quantity,
        a.total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        (a.total_sales - COALESCE(r.total_returned, 0)) AS net_sales
    FROM aggregated_sales a
    LEFT JOIN returned_sales r ON a.ws_item_sk = r.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    f.total_quantity,
    f.total_sales,
    f.total_returned,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 10000 THEN 'High Seller'
        WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Moderate Seller'
        ELSE 'Low Seller' 
    END AS sales_category
FROM final_sales f
JOIN item i ON f.ws_item_sk = i.i_item_sk
WHERE f.net_sales IS NOT NULL
ORDER BY f.net_sales DESC;
