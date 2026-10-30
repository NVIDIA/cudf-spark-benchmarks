
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city AS city,
        ca_state AS state,
        ca_zip AS zip,
        ca_country AS country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        CASE cd_gender 
            WHEN 'M' THEN 'Male' 
            WHEN 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status,
        cd_purchase_estimate AS purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_customer_sk = cd_demo_sk
),
SalesData AS (
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
    cd.customer_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.purchase_estimate,
    ad.full_address,
    ad.city,
    ad.state,
    ad.zip,
    ad.country,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_profit, 0) DESC) AS rank
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ad.state = 'CA' 
    AND cd.purchase_estimate > 1000
GROUP BY 
    cd.customer_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.purchase_estimate,
    ad.full_address,
    ad.city,
    ad.state,
    ad.zip,
    ad.country,
    sd.total_profit,
    sd.total_orders
ORDER BY 
    total_profit DESC
LIMIT 100;
