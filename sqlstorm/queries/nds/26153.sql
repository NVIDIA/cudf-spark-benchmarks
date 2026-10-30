
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_city ILIKE '%town%'
    AND cd.cd_gender = 'F'
), sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), returns_info AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    si.total_quantity,
    si.total_net_paid,
    COALESCE(ri.total_return_quantity, 0) AS total_return_quantity
FROM customer_info ci
LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN returns_info ri ON ci.c_customer_sk = ri.wr_returning_customer_sk
ORDER BY total_net_paid DESC, total_quantity DESC
LIMIT 100;
