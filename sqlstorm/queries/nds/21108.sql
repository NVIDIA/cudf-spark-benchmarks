
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_marital_status ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rank_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_customers AS (
    SELECT *
    FROM customer_summary
    WHERE rank_profit <= 10
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN c.c_birth_year IS NULL THEN 1 ELSE 0 END) AS null_birth_year_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    ai.ca_city,
    ai.ca_state,
    ai.customer_count,
    ai.null_birth_year_count,
    'Total Profit' AS descriptive_label,
    CASE 
        WHEN tc.total_net_profit > 10000 THEN 'High Profit'
        WHEN tc.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COALESCE((SELECT MAX(sr_return_amt) 
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = tc.c_customer_sk AND sr.sr_return_quantity > 0), 0) AS max_return_amt,
    (SELECT COUNT(*) 
     FROM web_returns wr 
     WHERE wr.wr_returning_customer_sk = tc.c_customer_sk) AS web_return_count
FROM 
    top_customers tc
LEFT JOIN 
    address_info ai ON ai.customer_count > 5 
ORDER BY 
    tc.total_net_profit DESC, 
    ai.null_birth_year_count ASC;
