WITH  sales_cte AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) as sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450000 AND 2450500  
    GROUP BY
        ws_bill_customer_sk
),
max_sales AS (
    SELECT
        ws_bill_customer_sk,
        MAX(total_sales) AS max_total_sales
    FROM
        sales_cte
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ma.max_total_sales AS customer_max_sales
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        max_sales ma ON c.c_customer_sk = ma.ws_bill_customer_sk
    WHERE
        cd.cd_purchase_estimate > 5000
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
),
address_info AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer_address ca
    JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_city LIKE 'San%'
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.customer_max_sales,
    address_info.ca_address_id,
    address_info.ca_city,
    address_info.ca_state,
    address_info.ca_country
FROM
    customer_info ci
JOIN
    address_info ON ci.c_customer_id IN (
        SELECT c.c_customer_id
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_city IN (SELECT DISTINCT ca_city FROM address_info)
    )
ORDER BY
    ci.customer_max_sales DESC,
    ci.c_last_name ASC;