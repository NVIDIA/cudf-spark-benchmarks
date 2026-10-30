
WITH  sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(i.i_brand, 'Unknown') AS brand,
        COALESCE(p.p_promo_name, 'No Promotion') AS promotion
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND p.p_discount_active = 'Y'
)
SELECT 
    ss.ws_item_sk,
    id.i_item_desc,
    id.brand,
    id.promotion,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ss.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    sales_summary ss
JOIN 
    item_details id ON ss.ws_item_sk = id.i_item_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
