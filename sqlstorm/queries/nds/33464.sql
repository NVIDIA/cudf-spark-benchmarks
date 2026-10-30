
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 1000
),
customer_totals AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
aggregated_data AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ct.total_orders) AS total_orders,
        SUM(ct.total_web_returns) AS total_web_returns,
        SUM(ct.total_net_profit) AS total_net_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_totals ct ON c.c_customer_sk = ct.c_customer_sk
    WHERE 
        ca.ca_state IS NOT NULL 
        AND ca.ca_city IS NOT NULL
    GROUP BY 
        ca.ca_city, ca.ca_state
),
ranked_data AS (
    SELECT 
        ad.ca_city, 
        ad.ca_state, 
        ad.customer_count, 
        ad.total_orders, 
        ad.total_web_returns, 
        ad.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_state ORDER BY ad.total_net_profit DESC) AS rank
    FROM 
        aggregated_data ad
)
SELECT 
    r.ca_city,
    r.ca_state,
    r.customer_count,
    r.total_orders,
    r.total_web_returns,
    r.total_net_profit,
    r.rank
FROM 
    ranked_data r
WHERE 
    r.rank <= 5
ORDER BY 
    r.ca_state, r.total_net_profit DESC;
