
WITH AddressSummary AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM
        customer_address
),
CustomerGender AS (
    SELECT
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_desc
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        AddressSummary.full_address,
        CustomerGender.gender_desc
    FROM
        web_sales AS ws
    LEFT JOIN customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN AddressSummary ON c.c_current_addr_sk = AddressSummary.ca_address_sk
    LEFT JOIN CustomerGender ON c.c_current_cdemo_sk = CustomerGender.cd_demo_sk
)
SELECT
    gender_desc,
    COUNT(*) AS total_orders,
    SUM(ws_quantity) AS total_items_sold,
    SUM(ws_ext_sales_price) AS total_revenue,
    AVG(ws_ext_sales_price) AS avg_order_value
FROM
    SalesDetails
GROUP BY
    gender_desc
ORDER BY
    total_revenue DESC;
