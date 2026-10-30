
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
FilteredSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        DENSE_RANK() OVER (ORDER BY sh.total_profit DESC) AS rank_within_group
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.rank = 1 AND sh.total_profit > (SELECT AVG(total) 
                                             FROM (SELECT SUM(ws_net_profit) AS total 
                                                   FROM web_sales 
                                                   GROUP BY ws_ship_customer_sk) AS avg_profit)
), 
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    INNER JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)

SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_profit,
    ai.ca_city,
    ai.ca_state
FROM 
    FilteredSales fs
LEFT JOIN 
    AddressInfo ai ON fs.c_customer_sk = ai.ca_address_sk
WHERE 
    ai.ca_city IS NOT NULL
ORDER BY 
    fs.total_profit DESC 
LIMIT 10;
