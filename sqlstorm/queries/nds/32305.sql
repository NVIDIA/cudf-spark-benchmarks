
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
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
        SUM(ss.total_quantity) AS total_sales_quantity,
        SUM(ss.total_profit) AS total_sales_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_summary ss ON ss.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ci.total_sales_quantity, 0) AS sales_quantity,
    COALESCE(ci.total_sales_profit, 0) AS sales_profit,
    CASE 
        WHEN ci.total_sales_profit IS NULL THEN 'No Sales'
        WHEN ci.total_sales_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS sales_status,
    DENSE_RANK() OVER (ORDER BY COALESCE(ci.total_sales_profit, 0) DESC) AS profit_rank
FROM customer_info ci
WHERE ci.ca_state = 'CA'
  AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY profit_rank
LIMIT 100;
