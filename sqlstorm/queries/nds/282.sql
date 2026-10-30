
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    ),
aggregate_stats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca_state
    HAVING 
        COUNT(DISTINCT c_customer_sk) >= 100
    ),
full_summary AS (
    SELECT 
        a.ca_state,
        a.customer_count,
        a.total_profit,
        COALESCE(r.rank_profit, 0) AS highest_rank
    FROM 
        aggregate_stats AS a
    LEFT JOIN 
        ranked_sales AS r ON a.total_profit = r.ws_net_profit
    )
SELECT 
    fs.ca_state,
    fs.customer_count,
    fs.total_profit,
    fs.highest_rank,
    CASE 
        WHEN fs.total_profit > 100000 THEN 'High Profit'
        WHEN fs.total_profit BETWEEN 50000 AND 100000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    full_summary AS fs
WHERE 
    fs.highest_rank = 1
ORDER BY 
    fs.total_profit DESC;
