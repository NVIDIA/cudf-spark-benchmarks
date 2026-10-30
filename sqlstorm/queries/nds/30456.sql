WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as ranked
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY 
        ws_item_sk
),
high_performers AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim) 
        AND (p.p_end_date_sk IS NULL OR p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim))
    WHERE 
        sd.ranked <= 10
)
SELECT 
    hp.ws_item_sk,
    hp.total_quantity,
    hp.total_sales,
    hp.i_item_desc,
    hp.i_current_price,
    CASE 
        WHEN hp.discount_active = 'Y' THEN 'Discount Applicable'
        ELSE 'No Discount'
    END AS discount_status
FROM 
    high_performers hp
ORDER BY 
    hp.total_sales DESC;