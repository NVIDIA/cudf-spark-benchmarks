
WITH  customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        COALESCE(MAX(ss.ss_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(MAX(ss.ss_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, cd.cd_gender
),
filtered_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_net_profit > 1000 THEN 'High Value'
            WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer_analysis
    WHERE 
        profit_rank <= 10
)
SELECT 
    cu.c_first_name || ' ' || cu.c_last_name AS full_name,
    cu.ca_city,
    cu.cd_gender,
    cu.total_net_profit,
    cu.total_transactions,
    cu.customer_value_segment,
    SUM(ws.ws_net_profit) AS web_sales_net_profit,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
FROM 
    filtered_customers cu
LEFT JOIN 
    web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_returns wr ON cu.c_customer_sk = wr.wr_returning_customer_sk
GROUP BY 
    cu.c_first_name, cu.c_last_name, cu.ca_city, cu.cd_gender, cu.total_net_profit, cu.total_transactions, cu.customer_value_segment
HAVING 
    SUM(ws.ws_net_profit) IS NOT NULL AND COUNT(DISTINCT wr.wr_order_number) > 0
ORDER BY 
    cu.total_net_profit DESC
LIMIT 5
OFFSET 0;
