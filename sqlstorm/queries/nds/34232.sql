
WITH  SalesHierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_state

    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        store s
    JOIN 
        catalog_sales cs ON s.s_store_sk = cs.cs_call_center_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_state
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(sh.total_net_profit) AS profit_contribution,
    CASE 
        WHEN SUM(sh.total_net_profit) IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesHierarchy sh ON sh.s_state = ca.ca_state
WHERE 
    (c.c_birth_year IS NOT NULL AND c.c_birth_year >= 1980)
    OR (c.c_preferred_cust_flag = 'Y')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(sh.total_net_profit) > 1000
ORDER BY 
    profit_contribution DESC;
