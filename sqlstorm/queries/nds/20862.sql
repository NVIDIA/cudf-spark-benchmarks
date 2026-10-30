WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
filtered_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_price
    FROM 
        ranked_sales
    WHERE 
        rn <= 10 
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(fs.total_sales, 0) AS total_sales,
    COALESCE(fs.avg_price, 0) AS avg_price,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS total_ca_stores,
    (SELECT COUNT(*) FROM customer_address WHERE ca_state = 'CA') AS total_ca_addresses
FROM 
    item i
LEFT JOIN 
    filtered_sales fs ON i.i_item_sk = fs.ws_item_sk
WHERE 
    (fs.avg_price IS NULL OR fs.avg_price > 50)
    AND i.i_rec_start_date <= cast('2002-10-01' as date)
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    total_sales DESC
LIMIT 20;