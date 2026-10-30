
WITH  customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE 
                   WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM customer_address ca
),
sales_data AS (
    SELECT 
        w.ws_sold_date_sk,
        SUM(w.ws_net_profit) AS total_profit,
        COUNT(DISTINCT w.ws_order_number) AS order_count
    FROM web_sales w
    WHERE w.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY w.ws_sold_date_sk
),
combined_data AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        sd.total_profit,
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY ai.ca_state ORDER BY sd.total_profit DESC) AS state_rank
    FROM customer_rank cr
    JOIN address_info ai ON cr.c_customer_sk = ai.ca_address_sk
    LEFT JOIN sales_data sd ON cr.c_customer_sk = sd.ws_sold_date_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    COALESCE(cd.total_profit, 0) AS total_profit,
    COALESCE(cd.order_count, 0) AS order_count,
    CASE 
        WHEN cd.total_profit IS NULL THEN 'No Sales'
        WHEN cd.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM combined_data cd
WHERE cd.state_rank <= 10
ORDER BY cd.ca_state, cd.total_profit DESC;
