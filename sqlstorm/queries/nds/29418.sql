
WITH AddressData AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        ca_state
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_credit_rating,
        a.full_address,
        s.total_sales,
        s.order_count
    FROM 
        CustomerData c
    LEFT JOIN 
        AddressData a ON c.ca_state = a.ca_state
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        c.cd_gender = 'F' 
        AND c.cd_marital_status = 'M'
        AND s.order_count > 10
)
SELECT 
    COUNT(*) AS qualifying_customers,
    AVG(total_sales) AS avg_sales,
    MIN(total_sales) AS min_sales,
    MAX(total_sales) AS max_sales
FROM 
    FinalReport;
