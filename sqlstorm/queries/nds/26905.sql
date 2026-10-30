
WITH customer_details AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_details AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_day_name
    FROM
        date_dim d
    WHERE
        d.d_year >= 1998
),
sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN
        date_details dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        ws.ws_item_sk
)
SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    dd.d_date,
    sd.total_quantity,
    sd.total_sales
FROM
    customer_details cd
JOIN
    sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
JOIN
    date_details dd ON dd.d_date = '2002-10-01'
WHERE
    cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
ORDER BY
    sd.total_sales DESC
LIMIT 10;
