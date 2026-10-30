
WITH CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesCTE AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.ca_city,
    c.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    c.cd_dep_count,
    c.cd_dep_employed_count,
    c.cd_dep_college_count,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM 
    CustomerCTE c
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.customer_sk
WHERE 
    c.cd_gender = 'F' AND
    c.cd_marital_status = 'M' AND
    c.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
