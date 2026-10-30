
WITH CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FormattedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type)) AS formatted_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer_address ca
),
CustomerDetails AS (
    SELECT 
        ca.formatted_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_address_sk,
        c.c_first_name,
        c.c_last_name,
        ca2.total_orders,
        ca2.total_spent,
        ca2.avg_purchase_estimate
    FROM CustomerAggregates ca2
    JOIN customer c ON c.c_customer_sk = ca2.c_customer_sk
    JOIN FormattedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.formatted_address AS address,
    CONCAT(cd.ca_city, ', ', cd.ca_state, ' ', cd.ca_zip) AS city_state_zip,
    cd.total_orders,
    cd.total_spent,
    cd.avg_purchase_estimate
FROM CustomerDetails cd
ORDER BY cd.total_spent DESC;
