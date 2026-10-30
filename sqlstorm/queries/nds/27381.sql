
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebSalesAggregated AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    wsa.total_spent,
    wsa.order_count
FROM 
    CustomerDetails cd
JOIN 
    CustomerAddresses ca ON cd.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    WebSalesAggregated wsa ON cd.c_customer_sk = wsa.ws_bill_customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000 
    AND ca.ca_state = 'CA'
ORDER BY 
    total_spent DESC, 
    cd.full_name;
