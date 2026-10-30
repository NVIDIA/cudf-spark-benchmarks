
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueItems AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_brand,
        i_current_price
    FROM 
        item
    WHERE 
        i_current_price IS NOT NULL
),
HighSales AS (
    SELECT 
        s.ws_item_sk AS item_sk,
        s.total_quantity,
        s.total_sales,
        i.i_item_desc,
        i.i_brand,
        (CASE 
            WHEN i.i_current_price > 100 THEN 'Premium'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Midrange'
            ELSE 'Affordable' 
        END) AS price_category
    FROM 
        SalesSummary s
    JOIN 
        HighValueItems i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.rank_sales <= 10
)
SELECT 
    h.item_sk,
    h.total_quantity,
    h.total_sales,
    h.i_item_desc,
    h.i_brand,
    h.price_category,
    COALESCE(ROUND(h.total_sales / NULLIF(h.total_quantity, 0), 2), 0) AS avg_sale_per_item
FROM 
    HighSales h
LEFT JOIN 
    promotion p ON h.item_sk = p.p_item_sk AND p.p_discount_active = 'Y'
ORDER BY 
    h.total_sales DESC
LIMIT 25;
