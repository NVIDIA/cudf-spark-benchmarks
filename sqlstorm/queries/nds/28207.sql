
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_email_address,
        c_current_addr_sk
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate 
    FROM 
        customer_demographics
),
OrderDetails AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cu.full_name,
        cu.c_birth_day,
        cu.c_birth_month,
        cu.c_birth_year,
        cu.c_email_address,
        ad.full_address,
        coalesce(ord.order_count, 0) AS order_count,
        coalesce(ord.total_spent, 0) AS total_spent,
        CASE 
            WHEN coalesce(ord.total_spent, 0) > 1000 THEN 'High Value'
            WHEN coalesce(ord.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        CustomerDetails cu
    JOIN 
        AddressDetails ad ON cu.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        OrderDetails ord ON cu.c_customer_sk = ord.customer_sk
)
SELECT 
    full_name,
    full_address,
    CONCAT(c_birth_day, '-', c_birth_month, '-', c_birth_year) AS birth_date,
    c_email_address,
    order_count,
    total_spent,
    customer_value
FROM 
    CombinedData
WHERE 
    customer_value IN ('High Value', 'Medium Value')
ORDER BY 
    total_spent DESC;
