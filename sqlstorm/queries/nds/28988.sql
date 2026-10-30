
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesByGender AS (
    SELECT 
        ci.cd_gender,
        COUNT(*) AS total_customers,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
        JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.cd_gender
),
SalesByMaritalStatus AS (
    SELECT 
        ci.cd_marital_status,
        COUNT(*) AS total_customers,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
        JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.cd_marital_status
),
SalesByCity AS (
    SELECT 
        ci.ca_city,
        COUNT(*) AS total_customers,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
        JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.ca_city
)
SELECT 
    'Gender' AS category, 
    cd_gender AS category_value, 
    total_customers, 
    total_sales 
FROM 
    SalesByGender
UNION ALL
SELECT 
    'Marital Status', 
    cd_marital_status, 
    total_customers, 
    total_sales 
FROM 
    SalesByMaritalStatus
UNION ALL
SELECT 
    'City', 
    ca_city, 
    total_customers, 
    total_sales 
FROM 
    SalesByCity
ORDER BY 
    category, 
    total_sales DESC;
