
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_number,
        ca.ca_street_type,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
        cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_zip,
        ca.ca_street_name, ca.ca_street_number, ca.ca_street_type
),
RankedCustomers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS gender_rank
    FROM
        CustomerDetails
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent,
    CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
FROM
    RankedCustomers
WHERE
    gender_rank <= 10
ORDER BY
    cd_gender, total_spent DESC;
