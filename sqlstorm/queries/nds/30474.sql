
WITH  sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_statistics AS (
    SELECT 
        c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS spend_rank
    FROM web_sales
    JOIN customer ON ws_ship_customer_sk = c_customer_sk
    GROUP BY c_customer_sk
),
recent_customers AS (
    SELECT 
        c_customer_sk,
        MIN(c_birth_year) AS year_of_birth,
        MAX(c_email_address) AS email_address
    FROM customer
    GROUP BY c_customer_sk
),
final_results AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        rc.year_of_birth,
        rc.email_address,
        COALESCE(st.total_profit, 0) AS recent_sales_profit
    FROM customer_statistics cs
    LEFT JOIN recent_customers rc ON cs.c_customer_sk = rc.c_customer_sk
    LEFT JOIN sales_trends st ON cs.c_customer_sk = st.ws_item_sk
    WHERE (rc.year_of_birth IS NOT NULL AND rc.year_of_birth > 1980)
    OR (cs.total_spent > 1000)
)

SELECT 
    f.c_customer_sk,
    f.total_orders,
    f.total_spent,
    CONCAT('Customer ', f.c_customer_sk, ' - Email: ', f.email_address) AS customer_details,
    CASE 
        WHEN f.recent_sales_profit > 0 THEN 'Profit Earned'
        ELSE 'No Recent Profit'
    END AS sales_status
FROM final_results f
WHERE f.total_spent IS NOT NULL
ORDER BY f.total_spent DESC
LIMIT 100;

