
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(ss.ss_ticket_number) AS total_tickets
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = '1')
    GROUP BY 
        ss.ss_store_sk
),
top_stores AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        t.total_store_profit,
        RANK() OVER (ORDER BY t.total_store_profit DESC) AS store_rank
    FROM 
        store s
    JOIN 
        store_sales_summary t ON s.s_store_sk = t.ss_store_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_profit,
    ts.s_store_id,
    ts.s_store_name,
    ts.total_store_profit
FROM 
    customer_sales cs
LEFT JOIN 
    top_stores ts ON cs.total_orders > 5
WHERE 
    cs.total_profit IS NOT NULL AND
    cs.total_profit > (SELECT AVG(total_profit) FROM customer_sales)
ORDER BY 
    cs.total_profit DESC, ts.total_store_profit ASC;
