
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_sales_price) / SUM(ws.ws_quantity) AS avg_sales_price,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_sales_price) AS catalog_sales,
        cs.cs_promo_sk
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws.ws_item_sk, cs.cs_item_sk, cs.cs_promo_sk
),
PromoData AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT sd.ws_item_sk) AS item_count,
        SUM(sd.total_sales) AS promo_sales,
        SUM(sd.total_quantity) AS promo_quantity
    FROM 
        promotion p
    JOIN 
        SalesData sd ON p.p_promo_sk = sd.cs_promo_sk
    GROUP BY 
        p.p_promo_id
),
FinalReport AS (
    SELECT 
        p.p_promo_id,
        pd.item_count,
        pd.promo_sales,
        pd.promo_quantity,
        pd.promo_sales / NULLIF(pd.promo_quantity, 0) AS avg_promo_sales_price
    FROM 
        PromoData pd
    JOIN 
        promotion p ON pd.promo_sales = (SELECT MAX(promo_sales) FROM PromoData)
)
SELECT 
    fr.p_promo_id,
    fr.item_count,
    fr.promo_sales,
    fr.promo_quantity,
    fr.avg_promo_sales_price
FROM 
    FinalReport fr
WHERE 
    fr.promo_quantity > 100
ORDER BY 
    fr.promo_sales DESC
LIMIT 10;
