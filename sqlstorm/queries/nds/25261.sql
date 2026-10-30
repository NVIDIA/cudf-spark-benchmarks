
WITH address_parts AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(c.c_email_address, ' (', cd.cd_gender, ')') AS email_gender,
        (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk) AS demo_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
order_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ci.full_name,
    ci.email_gender,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    os.total_quantity,
    os.total_sales
FROM
    customer_info ci
JOIN
    address_parts ap ON ci.c_customer_sk = ap.ca_address_sk
LEFT JOIN
    order_summary os ON ci.c_customer_sk = os.ws_bill_customer_sk
WHERE
    ap.ca_country = 'USA' AND ci.demo_count > 1
ORDER BY
    os.total_sales DESC
LIMIT
    100;
