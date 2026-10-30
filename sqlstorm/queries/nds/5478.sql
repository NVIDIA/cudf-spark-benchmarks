
WITH SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 AND 
        i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
PromotionInfo AS (
    SELECT 
        ps.p_item_sk,
        ps.p_promo_sk,
        SUM(ps.p_response_target) AS total_responses,
        COUNT(DISTINCT ps.p_promo_id) AS total_promotions
    FROM 
        promotion ps
    JOIN 
        SalesInfo si ON ps.p_item_sk = si.ws_item_sk
    GROUP BY 
        ps.p_item_sk, ps.p_promo_sk
)
SELECT 
    si.ws_item_sk,
    si.total_quantity,
    si.total_sales,
    COALESCE(pi.total_responses, 0) AS total_responses,
    COALESCE(pi.total_promotions, 0) AS total_promotions
FROM 
    SalesInfo si
LEFT JOIN 
    PromotionInfo pi ON si.ws_item_sk = pi.p_item_sk
ORDER BY 
    si.total_sales DESC
LIMIT 10;
