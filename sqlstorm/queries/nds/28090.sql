
WITH Address_Components AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),

Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),

Sales_Overview AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),

Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders
    FROM 
        customer c
    JOIN 
        Address_Components a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Customer_Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        Sales_Overview s ON c.c_customer_sk = s.ws_bill_customer_sk
)

SELECT 
    customer_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders
FROM 
    Customer_Stats
WHERE 
    UPPER(cd_gender) = 'F' 
    AND total_orders > 10
ORDER BY 
    total_sales DESC
LIMIT 100;
