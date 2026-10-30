
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
AggregateSales AS (
    SELECT 
        wd.d_year,
        SUM(sd.ws_net_paid) AS total_sales,
        COUNT(sd.ws_item_sk) AS item_count
    FROM 
        SalesData sd
    JOIN 
        date_dim wd ON sd.ws_sold_date_sk = wd.d_date_sk
    WHERE 
        sd.rn <= 10
    GROUP BY 
        wd.d_year
),
PromotionData AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    a.d_year,
    a.total_sales,
    a.item_count,
    COALESCE(p.promo_sales, 0) AS total_promo_sales,
    p.order_count
FROM 
    AggregateSales a
LEFT JOIN 
    PromotionData p ON a.total_sales > 1000
WHERE 
    a.d_year IS NOT NULL
ORDER BY 
    a.d_year DESC
LIMIT 100;
