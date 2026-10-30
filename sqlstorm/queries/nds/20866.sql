
WITH Recursive_CTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state IN ('NY', 'CA') 
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
    HAVING 
        SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk IS NOT NULL)
    
    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state NOT IN ('NY', 'CA') 
        AND ws.ws_net_profit IS NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
    HAVING 
        COUNT(distinct ws.ws_item_sk) > 0 
        AND SUM(COALESCE(ws.ws_net_profit, 0)) < (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk IS NOT NULL)
),
Ranked_Customers AS (
    SELECT 
        cte.*,
        RANK() OVER (PARTITION BY cte.ca_state ORDER BY cte.total_net_profit DESC) AS customer_rank
    FROM 
        Recursive_CTE cte
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_state,
    rc.total_net_profit,
    CASE 
        WHEN rc.customer_rank <= 10 THEN 'Top Performer'
        WHEN rc.total_net_profit IS NULL THEN 'No Profit Recorded'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    Ranked_Customers rc
WHERE 
    rc.total_net_profit IS NOT NULL
    AND (rc.total_net_profit > 1000 OR rc.ca_state IS NULL)
ORDER BY 
    rc.ca_state, rc.total_net_profit DESC;
