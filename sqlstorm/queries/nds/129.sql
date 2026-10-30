
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 20.00
), 
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    SUM(rs.ws_net_profit) AS TotalNetProfit,
    COUNT(DISTINCT rs.ws_item_sk) AS UniqueItems
FROM 
    AddressDetails ad
LEFT JOIN 
    RankedSales rs ON ad.CustomerCount > 10 AND rs.ws_sold_date_sk IN (
        SELECT 
            d.d_date_sk 
        FROM 
            date_dim d 
        WHERE 
            d.d_year = 2023 AND 
            d.d_weekend = 'Y'
    )
GROUP BY 
    ad.ca_city, ad.ca_state
HAVING 
    SUM(rs.ws_net_profit) IS NOT NULL AND 
    COUNT(DISTINCT rs.ws_item_sk) > 5
ORDER BY 
    TotalNetProfit DESC
LIMIT 10;
