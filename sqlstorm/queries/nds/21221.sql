
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) 
                              FROM web_sales ws2 
                              WHERE ws2.ws_item_sk = ws.ws_item_sk)
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'S'
), 
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS TotalProfit,
        COUNT(DISTINCT ss.ss_ticket_number) AS Transactions
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
    HAVING 
        SUM(ss.ss_net_profit) > 1000
)

SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    rs.ws_item_sk,
    rs.ws_order_number,
    rs.ws_sales_price,
    s.s_store_name,
    ss.TotalProfit,
    CASE 
        WHEN ss.Transactions > 50 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS StoreActivity,
    COALESCE((SELECT COUNT(*) 
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = ci.c_customer_sk 
                AND sr.sr_return_quantity > 0), 0) AS TotalReturns
FROM 
    CustomerInfo ci
JOIN 
    RankedSales rs ON ci.c_customer_sk = rs.ws_item_sk
JOIN 
    store s ON s.s_store_sk = rs.ws_item_sk
JOIN 
    StoreSalesSummary ss ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ci.GenderRank = 1
    AND (rs.ws_sales_price BETWEEN 10.00 AND 100.00 OR rs.ws_sales_price IS NULL)
ORDER BY 
    ci.c_last_name, 
    ci.c_first_name, 
    rs.ws_sales_price DESC
LIMIT 100;
