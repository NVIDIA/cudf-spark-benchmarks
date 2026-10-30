
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
DemographicDetails AS (
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
SalesTransactions AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ca.full_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        DemographicDetails cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6)
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit
FROM 
    SalesTransactions 
GROUP BY 
    full_address, cd_gender, cd_marital_status
ORDER BY 
    total_sales DESC, total_orders DESC
LIMIT 100;
