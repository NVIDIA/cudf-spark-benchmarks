
WITH CustomerPurchasingData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city, ca.ca_state
), RankedCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY ca_city ORDER BY total_profit DESC) AS rank
    FROM 
        CustomerPurchasingData
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    total_profit
FROM 
    RankedCustomers
WHERE 
    rank <= 5
ORDER BY 
    ca_city, total_profit DESC;
