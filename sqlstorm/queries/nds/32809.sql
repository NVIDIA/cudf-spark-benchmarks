
WITH  sales_cte AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk

    UNION ALL

    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rn
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk
),

customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

top_items AS (
    SELECT
        si.ws_item_sk,
        si.total_quantity,
        si.total_sales
    FROM
        sales_cte si
    WHERE
        si.rn = 1
)

SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_marital_status,
    ci.cd_gender,
    ci.customer_value,
    ti.total_quantity,
    ti.total_sales,
    RANK() OVER (ORDER BY ti.total_sales DESC) AS item_rank
FROM
    customer_info ci
LEFT JOIN
    top_items ti ON ci.c_customer_sk = ti.ws_item_sk
WHERE
    ci.cd_marital_status IS NOT NULL
ORDER BY
    item_rank;

