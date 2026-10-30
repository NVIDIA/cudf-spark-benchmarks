
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_education_status LIKE '%Graduate%'
),
CustomerAddress AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM
        customer_address ca
    WHERE
        ca.ca_city IN ('Los Angeles', 'New York', 'Chicago')
),
SalesSummary AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    ss.total_sales,
    ss.total_orders
FROM
    RankedCustomers rc
JOIN
    CustomerAddress ca ON rc.c_customer_sk = ca.ca_address_sk
LEFT JOIN
    SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
WHERE
    rc.rn <= 10
ORDER BY
    rc.cd_gender,
    total_sales DESC;
