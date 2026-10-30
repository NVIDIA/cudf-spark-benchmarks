WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
PromotionData AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws_order_number) AS promo_order_count,
        SUM(ws_ext_sales_price) AS total_promoted_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS top_ranking
    FROM 
        SalesData sd
    WHERE 
        sd.rank_sales = 1
),
ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    COALESCE(s.total_quantity, 0) AS sold_quantity,
    COALESCE(r.total_return_quantity, 0) AS returned_quantity,
    COALESCE(p.promo_order_count, 0) AS promotion_count,
    COALESCE(p.total_promoted_sales, 0.00) AS total_promotions_sales,
    (COALESCE(s.total_sales, 0) - COALESCE(p.total_promoted_sales, 0.00)) AS net_sales_after_promo
FROM 
    item ci
LEFT JOIN 
    TopItems s ON ci.i_item_sk = s.ws_item_sk
LEFT JOIN 
    ItemReturns r ON ci.i_item_sk = r.wr_item_sk
LEFT JOIN 
    PromotionData p ON ci.i_item_sk = p.p_promo_sk
WHERE 
    ci.i_current_price > 0 
    AND ci.i_rec_start_date <= cast('2002-10-01' as date) 
    AND (ci.i_rec_end_date IS NULL OR ci.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    net_sales_after_promo DESC
LIMIT 10;