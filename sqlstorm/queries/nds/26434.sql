
WITH AddressDetails AS (
    SELECT 
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_customer_sk
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        cd_demo_sk
    FROM 
        customer_demographics
),
Sales AS (
    SELECT 
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ws_order_number,
        ws_bill_customer_sk,
        ws_ship_customer_sk
    FROM 
        web_sales
),
CombinedData AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        c.full_name,
        c.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        s.ws_quantity,
        s.ws_sales_price,
        s.ws_net_profit
    FROM 
        AddressDetails a
    JOIN 
        CustomerDetails c ON a.ca_address_sk = c.c_customer_sk
    JOIN 
        Demographics d ON c.c_customer_sk = d.cd_demo_sk
    JOIN 
        Sales s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    full_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price) AS total_sales_price,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    CombinedData
GROUP BY 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    full_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate
ORDER BY 
    total_net_profit DESC
LIMIT 100;
