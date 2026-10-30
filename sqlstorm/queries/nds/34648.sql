
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 0
),
store_summary AS (
    SELECT 
        s.s_store_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM 
        store AS s
    LEFT JOIN 
        store_sales AS ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ss.s_store_id,
    ss.total_sales,
    ss.total_sales_profit,
    CASE 
        WHEN ss.total_sales_profit IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status
FROM 
    top_customers AS tc
LEFT JOIN 
    store_summary AS ss ON ss.total_sales > 100
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_profit DESC;
