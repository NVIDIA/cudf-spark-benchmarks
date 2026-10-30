
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_quantity,
        s.total_profit
    FROM
        customer c
    JOIN sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE
        s.rank <= 10
),
customer_addresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        c.c_customer_id
    FROM
        customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
reasons AS (
    SELECT
        r.r_reason_desc,
        COUNT(sr_reason_sk) AS return_count
    FROM
        store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        r.r_reason_desc
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    COALESCE(r.r_reason_desc, 'No Returns') AS return_reason,
    COALESCE(r.return_count, 0) AS return_count,
    tc.total_quantity,
    tc.total_profit
FROM
    top_customers tc
LEFT JOIN customer_addresses ca ON tc.c_customer_id = ca.c_customer_id
LEFT JOIN reasons r ON r.return_count > 0
ORDER BY
    tc.total_profit DESC, 
    tc.total_quantity DESC;
