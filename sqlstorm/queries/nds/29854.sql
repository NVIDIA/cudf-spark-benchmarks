
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateSales AS (
    SELECT
        w.ws_bill_customer_sk,
        SUM(w.ws_ext_sales_price) AS total_sales,
        COUNT(w.ws_order_number) AS total_orders,
        MIN(d.d_date) AS first_order_date,
        MAX(d.d_date) AS last_order_date
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.ws_bill_customer_sk
)
SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    ds.total_sales,
    ds.total_orders,
    ds.first_order_date,
    ds.last_order_date
FROM CustomerDetails cd
LEFT JOIN DateSales ds ON cd.c_customer_sk = ds.ws_bill_customer_sk
WHERE cd.cd_purchase_estimate > 1000
ORDER BY ds.total_sales DESC
LIMIT 100;
