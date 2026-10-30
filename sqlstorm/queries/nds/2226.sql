WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_color, ''), 'N/A') AS item_color
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
)
SELECT 
    id.i_item_desc,
    id.item_color,
    COALESCE(sd.total_quantity, 0) AS quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales_amount,
    CASE 
        WHEN sd.sales_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    item_details id
LEFT JOIN 
    sales_data sd ON id.i_item_sk = sd.ws_item_sk
WHERE 
    id.i_current_price < (SELECT AVG(i_current_price) FROM item)
ORDER BY 
    total_sales_amount DESC
LIMIT 10;