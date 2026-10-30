
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as PriceRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451536 AND 2451540
),
PromotionStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT cs_order_number) AS PromotionOrderCount,
        SUM(cs_net_profit) AS TotalNetProfit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    ca.ca_state,
    AVG(RS.ws_sales_price) AS AvgWebSalesPrice,
    SUM(CASE WHEN PS.PromotionOrderCount > 0 THEN PS.TotalNetProfit ELSE 0 END) AS TotalNetProfitFromPromotions,
    COUNT(DISTINCT c.c_customer_id) AS UniqueCustomers
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales RS ON c.c_customer_sk = RS.ws_item_sk
LEFT JOIN 
    PromotionStats PS ON PS.p_promo_sk = RS.ws_item_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    AvgWebSalesPrice DESC
LIMIT 10;
