
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_address_sk
    FROM 
        customer_address
), DistinguishedCustomers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND 
        cd_marital_status = 'M' AND 
        cd_purchase_estimate > 5000
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_demo_sk,
        d.cd_gender
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DistinguishedCustomers d ON c.c_current_cdemo_sk = d.cd_demo_sk
), SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    sd.total_profit IS NOT NULL OR sd.total_profit IS NULL
ORDER BY 
    total_profit DESC
LIMIT 100;
