
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_location_type
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_purchase_estimate,
        sales.total_orders,
        sales.total_net_profit,
        sales.total_sales
    FROM 
        customer cust
    JOIN 
        AddressDetails addr ON cust.c_current_addr_sk = addr.ca_address_sk
    JOIN 
        Demographics dem ON cust.c_current_cdemo_sk = dem.cd_demo_sk
    LEFT JOIN 
        SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    full_address,
    ca_city,
    ca_state,
    total_orders,
    total_sales,
    total_net_profit,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    cd_marital_status,
    cd_purchase_estimate
FROM 
    CombinedData
WHERE 
    total_sales > 1000
ORDER BY 
    total_net_profit DESC
LIMIT 100;
