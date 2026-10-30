
WITH customer_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        SUBSTRING(UPPER(c.c_email_address), 1, 10) AS email_substr
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    cd.c_customer_id,
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ss.total_orders,
    ss.total_spent,
    CASE
        WHEN ss.total_spent >= 1000 THEN 'Premium'
        WHEN ss.total_spent >= 500 THEN 'Regular'
        ELSE 'Casual'
    END AS customer_category
FROM
    customer_data cd
LEFT JOIN
    sales_summary ss ON cd.c_customer_id = ss.c_customer_id
WHERE
    cd.name_length > 20
ORDER BY
    ss.total_spent DESC;
