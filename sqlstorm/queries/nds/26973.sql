
WITH Address_Concat AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status
    FROM 
        customer c
    JOIN 
        Address_Concat a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Customer_Demo d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
Purchase_Stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws 
    JOIN 
        Customer_Info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ps.purchase_count,
    ps.total_spent
FROM 
    Customer_Info ci
LEFT JOIN 
    Purchase_Stats ps ON ci.c_customer_sk = ps.c_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
ORDER BY 
    ps.total_spent DESC
LIMIT 100;
