WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        customer c 
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.total_net_profit), 0) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    AVG(a.total_sales) AS avg_sales,
    COUNT(DISTINCT a.c_customer_sk) AS unique_customer_count,
    MAX(a.total_sales) AS highest_sales
FROM 
    AggregateSales a 
JOIN 
    customer_address ca ON a.c_customer_sk = ca.ca_address_sk 
WHERE 
    ca.ca_state IN ('CA', 'TX') 
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    avg_sales DESC
LIMIT 10;