
WITH AddressString AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        CURRENT_TIMESTAMP AS query_time,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
)
SELECT 
    a.customer_name,
    a.full_address,
    a.cd_gender,
    a.cd_marital_status,
    a.cd_education_status,
    SUM(sd.ws_sales_price) AS total_spent,
    COUNT(sd.ws_order_number) AS total_orders,
    MAX(sd.query_time) AS latest_query_time
FROM 
    AddressString a
LEFT JOIN 
    SalesData sd ON a.customer_name LIKE CONCAT('%', CAST(sd.ws_order_number AS STRING), '%')
WHERE 
    a.cd_gender = 'F'
GROUP BY 
    a.customer_name, a.full_address, a.cd_gender, a.cd_marital_status, a.cd_education_status 
ORDER BY 
    total_spent DESC, a.customer_name ASC
LIMIT 100;
