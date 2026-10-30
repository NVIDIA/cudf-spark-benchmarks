
WITH FormattedCustomerAddress AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM customer_address
),
FullCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        ca.city_state_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN FormattedCustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerPurchaseSummary AS (
    SELECT 
        fb.c_customer_sk AS customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        SUM(ws.ws_quantity) AS total_quantity
    FROM FullCustomerInfo fb
    JOIN web_sales ws ON fb.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY fb.c_customer_sk
)
SELECT 
    f.full_name,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(c.avg_order_value, 0) AS avg_order_value,
    COALESCE(c.total_quantity, 0) AS total_quantity,
    f.full_address,
    f.city_state_zip
FROM FullCustomerInfo f
LEFT JOIN CustomerPurchaseSummary c ON f.c_customer_sk = c.customer_sk
ORDER BY total_orders DESC, avg_order_value DESC
LIMIT 50;
