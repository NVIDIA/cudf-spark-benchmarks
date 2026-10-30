
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_country
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummaries AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        ss.total_sales,
        ss.order_count
    FROM CustomerDetails cd
    JOIN SalesSummaries ss ON cd.c_customer_sk = ss.c_customer_sk
    ORDER BY ss.total_sales DESC
    LIMIT 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    total_sales,
    order_count,
    REPLACE(full_name, ' ', '_') AS full_name_underscore,
    CONCAT(UPPER(SUBSTRING(full_name, 1, 1)), LOWER(SUBSTRING(full_name, 2))) AS formatted_name
FROM TopCustomers;
