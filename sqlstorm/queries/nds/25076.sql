
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS city,
        TRIM(UPPER(ca_state)) AS state,
        TRIM(ca_zip) AS zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date AS date_of_birth,
        cd.cd_gender,
        cd.cd_marital_status,
        cc.cc_name AS call_center_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy AND c.c_birth_year = d.d_year
    JOIN call_center cc ON c.c_customer_sk = cc.cc_call_center_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ac.full_address,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status
    FROM web_sales ws
    JOIN AddressComponents ac ON ws.ws_bill_addr_sk = ac.ca_address_sk
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    full_address,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN ws_order_number END) AS male_orders,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN ws_order_number END) AS female_orders,
    COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN ws_order_number END) AS married_orders,
    COUNT(DISTINCT CASE WHEN cd_marital_status = 'S' THEN ws_order_number END) AS single_orders
FROM SalesData
GROUP BY full_address
ORDER BY total_sales DESC
LIMIT 100;
