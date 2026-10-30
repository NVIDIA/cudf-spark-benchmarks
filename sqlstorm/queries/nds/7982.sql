
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90 AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
), CustomerDemographic AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM customer_demographics
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sd.total_sales,
        sd.total_orders,
        sd.last_purchase_date
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographic cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.c_first_name || ' ' || cd.c_last_name AS full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.total_sales,
    cd.total_orders,
    COUNT(CASE WHEN cd.last_purchase_date >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 THEN 1 END) AS recent_buyers
FROM CustomerDetails cd
GROUP BY 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.total_sales,
    cd.total_orders
ORDER BY total_sales DESC
LIMIT 100;
