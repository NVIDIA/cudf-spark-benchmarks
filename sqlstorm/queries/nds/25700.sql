
WITH CustomerAddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer_address ca
),
CustomerDemographicsDetails AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM
        customer_demographics cd
),
CustomerFullDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address,
        c.c_birth_month,
        c.c_birth_year,
        ca.full_address,
        dem.cd_gender,
        dem.cd_marital_status
    FROM
        customer c
    JOIN CustomerAddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographicsDetails dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
)
SELECT 
    cfd.customer_name,
    cfd.c_email_address,
    cfd.full_address,
    cfd.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    CustomerFullDetails cfd
LEFT JOIN 
    web_sales ws ON cfd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cfd.customer_name, cfd.c_email_address, cfd.full_address, cfd.cd_gender
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_spent DESC;
