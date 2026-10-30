
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        web_sales ws
    JOIN
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
    ORDER BY
        total_spent DESC
    LIMIT 10
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.purchase_estimate,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    tc.total_spent
FROM
    CustomerInfo ci
JOIN
    TopCustomers tc ON ci.c_customer_sk = tc.c_customer_sk
WHERE
    ci.cd_gender = 'F' AND
    ci.purchase_estimate > 1000
ORDER BY
    total_spent DESC;
