
WITH RankedSales AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_net_profit,
        c.c_customer_id,
        c.c_first_name AS FirstName,
        c.c_last_name AS LastName,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = '2002-10-01')
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_id
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
ProfitableCustomers AS (
    SELECT 
        r.c_customer_id,
        r.FirstName,
        r.LastName,
        ca.ca_city,
        ca.ca_state,
        r.ws_sales_price,
        r.ws_net_profit
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerAddresses ca ON r.c_customer_id = ca.c_customer_id
    WHERE 
        r.ProfitRank <= 5
)
SELECT 
    p.c_customer_id,
    p.FirstName,
    p.LastName,
    p.ca_city,
    p.ca_state,
    COALESCE(SUM(p.ws_net_profit), 0) AS TotalNetProfit,
    COUNT(DISTINCT p.ws_sales_price) AS UniqueSalesPrices
FROM 
    ProfitableCustomers p
GROUP BY 
    p.c_customer_id,
    p.FirstName,
    p.LastName,
    p.ca_city,
    p.ca_state
HAVING 
    COUNT(DISTINCT p.ws_sales_price) > 1
ORDER BY 
    TotalNetProfit DESC;
