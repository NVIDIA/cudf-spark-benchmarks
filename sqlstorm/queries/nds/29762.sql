
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
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
        cd_dep_count
    FROM 
        customer_demographics
), 
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws_list_price) AS avg_order_value
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk, ws_ship_customer_sk
)
SELECT 
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    COUNT(s.total_orders) AS order_count,
    SUM(s.total_revenue) AS total_revenue,
    AVG(s.avg_order_value) AS average_order_value
FROM 
    AddressParts a
JOIN 
    Demographics d ON d.cd_demo_sk = a.ca_address_sk
LEFT JOIN 
    SalesDetails s ON s.ws_bill_customer_sk = a.ca_address_sk OR s.ws_ship_customer_sk = a.ca_address_sk
WHERE 
    a.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    a.full_address, d.cd_gender, d.cd_marital_status
ORDER BY 
    total_revenue DESC
LIMIT 100;
