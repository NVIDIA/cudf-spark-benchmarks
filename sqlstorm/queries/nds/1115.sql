
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.rank_profit <= 10
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.ca_city,
    hvc.ca_state,
    hvc.ca_country,
    COALESCE(SUM(ss.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(ss.total_profit), 0) AS total_profit,
    CASE 
        WHEN hvc.cd_gender = 'M' THEN 'Mr. ' || hvc.c_last_name
        ELSE 'Ms. ' || hvc.c_last_name
    END AS full_name,
    COUNT(ws_item_sk) AS purchase_count
FROM high_value_customers hvc
LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN sales_summary ss ON hvc.c_customer_sk = ss.ws_bill_customer_sk
GROUP BY 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.ca_city,
    hvc.ca_state,
    hvc.ca_country
ORDER BY total_profit DESC;
