WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
), TopItems AS (
    SELECT 
        ri.ws_item_sk,
        total_sales,
        total_orders
    FROM 
        RankedSales ri
    WHERE 
        ri.rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_orders,
    i.i_product_name,
    i.i_category,
    p.p_promo_name
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion p ON i.i_item_sk = p.p_item_sk AND p.p_discount_active = 'Y'
ORDER BY 
    ti.total_sales DESC;