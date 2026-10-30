
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        SUBSTR(c.c_birth_country, 1, 3) AS country_code,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Analysis AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Result_Set AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.country_code,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        sa.total_quantity,
        sa.total_sales,
        sa.total_tax
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Analysis sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    full_name,
    ca_city,
    ca_state,
    country_code,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_quantity,
    total_sales,
    total_tax
FROM 
    Result_Set
WHERE 
    total_sales > 1000
ORDER BY 
    sales_rank;
