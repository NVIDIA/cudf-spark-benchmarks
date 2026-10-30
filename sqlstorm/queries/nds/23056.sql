WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        COALESCE(NULLIF(ws.ws_sales_price - ws.ws_net_paid, 0), 0) AS AdjustedProfit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
HighProfitSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.ws_net_profit,
        rs.AdjustedProfit
    FROM 
        RankedSales rs
    WHERE 
        rs.ProfitRank = 1
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(hp.AdjustedProfit) AS TotalAdjustedProfit,
    CASE 
        WHEN SUM(hp.AdjustedProfit) > 1000 THEN 'High Roller'
        WHEN SUM(hp.AdjustedProfit) > 500 THEN 'Average Joe'
        ELSE 'Low Stakes'
    END AS ProfitCategory
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    HighProfitSales hp ON c.c_customer_sk = hp.ws_item_sk  
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(hp.AdjustedProfit) IS NOT NULL 
    AND COUNT(DISTINCT hp.ws_order_number) > 1
ORDER BY 
    TotalAdjustedProfit DESC 
LIMIT 10;