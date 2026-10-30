
WITH  sales_rank AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
), 
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
address_counts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cs_ext_sales_price, 0)) AS total_sales
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        ca_state
), 
ranked_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    a.ca_state,
    a.customer_count,
    a.total_sales,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_orders,
    rc.total_net_profit,
    COALESCE(AVG(pr.ws_net_profit), 0) AS avg_profit_per_order
FROM 
    address_counts a
JOIN 
    ranked_customers rc ON rc.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_current_addr_sk IS NOT NULL)
LEFT JOIN 
    sales_rank pr ON rc.c_customer_sk = pr.ws_sold_date_sk
WHERE 
    a.customer_count > 10
GROUP BY 
    a.ca_state, 
    a.customer_count,
    a.total_sales,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_orders,
    rc.total_net_profit
ORDER BY 
    a.ca_state,
    rc.total_net_profit DESC;
