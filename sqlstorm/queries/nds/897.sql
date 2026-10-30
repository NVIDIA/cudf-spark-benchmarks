WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_web_site_sk, 
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        ws_item_sk, 
        ws_web_site_sk
),
SalesWithPromotion AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_web_site_sk,
        rs.total_quantity, 
        p.p_promo_id, 
        p.p_discount_active
    FROM 
        RankedSales rs
    LEFT JOIN 
        promotion p ON rs.ws_item_sk = p.p_item_sk
    WHERE 
        rs.rank <= 10
),
SalesData AS (
    SELECT 
        s.ws_item_sk,
        s.ws_web_site_sk,
        s.total_quantity,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
        CASE 
            WHEN s.total_quantity > 100 THEN 'High Demand'
            WHEN s.total_quantity > 50 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS demand_category
    FROM 
        SalesWithPromotion s
    LEFT JOIN 
        promotion p ON s.p_promo_id = p.p_promo_id
)
SELECT 
    sd.promo_name,
    sd.demand_category,
    COUNT(DISTINCT sd.ws_web_site_sk) AS unique_websites,
    SUM(sd.total_quantity) AS total_sold_quantity
FROM 
    SalesData sd
GROUP BY 
    sd.promo_name, 
    sd.demand_category
ORDER BY 
    total_sold_quantity DESC;