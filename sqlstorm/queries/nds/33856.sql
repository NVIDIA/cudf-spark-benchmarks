
WITH  SalesHierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS Sales_Rank
    FROM 
        store s 
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS Total_Sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
StoreReturns AS (
    SELECT 
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS Total_Returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_store_sk
),
ReturnCounts AS (
    SELECT 
        sr.sr_store_sk,
        COUNT(*) AS Total_Return_Count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_store_sk
)
SELECT 
    sh.s_store_name,
    COALESCE(sh.Total_Sales, 0) AS Total_Sales,
    COALESCE(pr.Total_Sales, 0) AS Promo_Sales,
    COALESCE(rt.Total_Returns, 0) AS Total_Returns,
    COALESCE(rc.Total_Return_Count, 0) AS Total_Return_Count,
    ROUND(COALESCE(sh.Total_Sales, 0) - COALESCE(rt.Total_Returns, 0), 2) AS Net_Sales,
    CASE 
        WHEN sh.Total_Sales IS NOT NULL AND rt.Total_Returns IS NOT NULL THEN 
            (ROUND((COALESCE(rt.Total_Returns, 0) / sh.Total_Sales) * 100, 2)) 
        ELSE 
            NULL 
    END AS Return_Percentage
FROM 
    SalesHierarchy sh
LEFT JOIN 
    Promotions pr ON sh.s_store_sk = pr.p_promo_sk
LEFT JOIN 
    StoreReturns rt ON sh.s_store_sk = rt.sr_store_sk
LEFT JOIN 
    ReturnCounts rc ON sh.s_store_sk = rc.sr_store_sk
WHERE 
    (sh.Total_Sales > 10000 OR rc.Total_Return_Count > 5) 
ORDER BY 
    Net_Sales DESC;
