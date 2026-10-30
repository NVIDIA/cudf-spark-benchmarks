
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerName AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    cn.full_name,
    cn.cd_gender,
    cn.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    sd.total_sales,
    sd.number_of_orders,
    ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
FROM 
    CustomerName cn
JOIN 
    AddressInfo ai ON cn.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesData sd ON cn.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ai.ca_state = 'NY' 
    AND sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC, 
    cn.full_name;
