
WITH RankedCustomers AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
SalesInfo AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS num_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.num_orders, 0) AS num_orders,
    CASE 
        WHEN rc.rn <= 10 THEN 'Top 10 Customer per Gender'
        ELSE 'Other Customers'
    END AS customer_rank
FROM 
    RankedCustomers rc
LEFT JOIN 
    AddressInfo ai ON rc.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON rc.c_customer_sk = si.ws_ship_customer_sk
WHERE 
    rc.cd_education_status LIKE '%Graduate%'
ORDER BY 
    rc.cd_gender, total_sales DESC;
