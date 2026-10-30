
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.ca_city,
        rc.ca_state,
        rc.cd_gender,
        rc.cd_marital_status
    FROM
        RankedCustomers rc
    WHERE
        rc.rnk <= 5
)
SELECT
    ca.ca_state,
    rc.cd_gender,
    COUNT(DISTINCT rc.c_customer_sk) AS customer_count,
    ARRAY_AGG(DISTINCT rc.c_first_name || ' ' || rc.c_last_name) AS customer_names
FROM
    TopCustomers rc
JOIN
    customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
GROUP BY
    ca.ca_state,
    rc.cd_gender
ORDER BY
    ca.ca_state,
    customer_count DESC;
