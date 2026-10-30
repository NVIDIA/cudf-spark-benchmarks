
WITH sales_totals AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
        AND ws.ws_ship_date_sk BETWEEN 2458882 AND 2458888
    GROUP BY 
        ws.ws_item_sk
), 
customer_total AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    SUM(st.total_profit) AS total_profit,
    SUM(ct.total_spent) AS total_revenue,
    COUNT(DISTINCT ct.c_customer_sk) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_totals st ON c.c_customer_sk = st.ws_item_sk
LEFT JOIN 
    customer_total ct ON c.c_customer_sk = ct.c_customer_sk
WHERE 
    ca.ca_country = 'USA' 
    AND (ct.order_count > 5 OR st.rank = 1)
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_profit DESC
LIMIT 10;
