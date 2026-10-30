
WITH Address AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM customer_address
),
Customer AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Statistics AS (
    SELECT 
        c.full_name, 
        a.full_address, 
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        ws.total_sales,
        ws.order_count,
        ROW_NUMBER() OVER (ORDER BY ws.total_sales DESC) AS rank
    FROM Customer c
    JOIN Address a ON c.c_customer_sk = a.ca_address_sk
    JOIN WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)

SELECT 
    rank,
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count
FROM Statistics
WHERE order_count > 5
ORDER BY total_sales DESC, full_name ASC;
