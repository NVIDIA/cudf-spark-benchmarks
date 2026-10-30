
WITH processed_customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
        LENGTH(c.c_email_address) AS email_length,
        LEFT(c.c_email_address, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY')
),

purchase_summary AS (
    SELECT
        ccd.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM
        processed_customer_data ccd
    JOIN
        web_sales ws ON ccd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        ccd.c_customer_sk
)

SELECT
    pcd.full_name,
    pcd.ca_city,
    pcd.ca_state,
    pcd.zip_prefix,
    COALESCE(ps.total_orders, 0) AS total_orders,
    COALESCE(ps.total_spent, 0) AS total_spent,
    CASE
        WHEN COALESCE(ps.total_spent, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(ps.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM
    processed_customer_data pcd
LEFT JOIN
    purchase_summary ps ON pcd.c_customer_sk = ps.c_customer_sk
ORDER BY
    total_spent DESC;
