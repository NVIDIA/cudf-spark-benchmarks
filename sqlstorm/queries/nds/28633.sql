
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_length
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesByCustomer AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
PerformanceMetrics AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ab.full_address,
        sb.total_net_profit,
        sb.total_orders,
        ab.street_length
    FROM 
        CustomerDetails cd 
    LEFT JOIN 
        AddressDetails ab ON cd.c_customer_sk = ab.ca_address_sk
    LEFT JOIN 
        SalesByCustomer sb ON cd.c_customer_sk = sb.ws_bill_customer_sk
)
SELECT 
    pm.full_name,
    pm.cd_gender,
    pm.cd_marital_status,
    pm.cd_purchase_estimate,
    pm.cd_credit_rating,
    pm.full_address,
    pm.total_net_profit,
    pm.total_orders,
    CASE 
        WHEN pm.street_length > 30 THEN 'Long Address' 
        ELSE 'Short Address' 
    END AS address_type
FROM 
    PerformanceMetrics pm
WHERE 
    pm.total_net_profit > 1000 AND 
    pm.cd_gender = 'F'
ORDER BY 
    pm.total_net_profit DESC, pm.full_name;
