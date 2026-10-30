
WITH Aggregated AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
TopCustomers AS (
    SELECT
        full_name,
        ca_city,
        ca_state,
        total_orders,
        total_spent,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank
    FROM
        Aggregated
)
SELECT
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_spent
FROM
    TopCustomers
WHERE
    rank <= 5
ORDER BY
    ca_state, total_spent DESC;
