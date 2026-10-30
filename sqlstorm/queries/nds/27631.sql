
WITH Address AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_address_sk
    FROM
        customer_address
),
Customer AS (
    SELECT
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        c_first_shipto_date_sk
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
Sales AS (
    SELECT
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ws_ship_addr_sk
    FROM
        web_sales
    GROUP BY
        ws_ship_addr_sk
),
CompleteInfo AS (
    SELECT
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        s.total_sales,
        s.order_count,
        a.full_address,
        a.ca_city,
        a.ca_state
    FROM
        Customer c
    JOIN
        Sales s ON c.c_first_shipto_date_sk = s.ws_ship_addr_sk
    JOIN
        Address a ON s.ws_ship_addr_sk = a.ca_address_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    full_address,
    ca_city,
    ca_state,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    CompleteInfo
ORDER BY
    total_sales DESC
LIMIT 100;
