
WITH customer_details AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM
        store_sales ss
    GROUP BY
        ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_customer_sk
),
joined_data AS (
    SELECT
        cd.c_customer_sk,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sd.total_sales,
        sd.purchase_count
    FROM
        customer_details cd
    LEFT JOIN
        sales_data sd ON cd.c_customer_sk = sd.ss_customer_sk
)
SELECT
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(purchase_count, 0) AS purchase_count,
    CASE
        WHEN cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS value_category
FROM
    joined_data
WHERE
    ca_state IN ('CA', 'NY', 'TX')
ORDER BY
    total_sales DESC, purchase_count DESC
LIMIT 100;
