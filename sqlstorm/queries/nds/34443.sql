
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
),
highest_sales AS (
    SELECT 
        ss_store_sk,
        COALESCE(SUM(ss_net_profit), 0) AS store_total_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
final_report AS (
    SELECT 
        ca_state,
        SUM(total_net_profit) AS total_profit,
        COUNT(DISTINCT total_orders) AS total_transactions,
        MAX(store_total_profit) AS max_store_profit,
        MIN(store_total_profit) AS min_store_profit
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        sales_summary s ON c.c_first_sales_date_sk = s.ws_sold_date_sk
    LEFT JOIN 
        highest_sales hs ON hs.ss_store_sk = c.c_customer_sk
    GROUP BY 
        ca_state
    HAVING 
        SUM(total_net_profit) > 10000
)
SELECT 
    ca_state,
    total_profit,
    total_transactions,
    max_store_profit,
    min_store_profit,
    CASE 
        WHEN total_profit > (SELECT AVG(total_profit) FROM final_report) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_category
FROM 
    final_report
ORDER BY 
    total_profit DESC;
