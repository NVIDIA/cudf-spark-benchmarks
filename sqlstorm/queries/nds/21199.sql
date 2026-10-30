
WITH customer_statistics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(AVG(ws.ws_net_profit), 0) AS avg_net_profit,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_quantity) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT *
    FROM customer_statistics
    WHERE total_orders > 5 AND avg_net_profit > 100
),
address_summary AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_state
),
customer_address_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(a.ca_city, 'Unknown') AS city,
        COALESCE(a.ca_state, 'Unknown') AS state,
        cs.total_quantity,
        cs.total_orders,
        cs.avg_net_profit
    FROM top_customers cs
    LEFT JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT
    cai.full_name,
    cai.city,
    cai.state,
    cai.total_quantity,
    cai.total_orders,
    cai.avg_net_profit,
    asum.customer_count,
    asum.total_net_paid
FROM customer_address_info cai
JOIN address_summary asum ON asum.ca_state = cai.state
ORDER BY cai.avg_net_profit DESC, asum.total_net_paid ASC
LIMIT 10
