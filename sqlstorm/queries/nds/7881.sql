
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c_customer_sk,
        total_sales,
        order_count,
        avg_net_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
sales_by_state AS (
    SELECT 
        ca.ca_state, 
        SUM(cs.total_sales) AS state_sales, 
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        top_customers cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    sb.state_sales,
    sb.customer_count,
    (sb.state_sales / NULLIF(sb.customer_count, 0)) AS avg_sales_per_customer,
    RANK() OVER (ORDER BY sb.state_sales DESC) AS state_sales_rank
FROM 
    sales_by_state sb
WHERE 
    sb.customer_count > 0
ORDER BY 
    sb.state_sales DESC;
