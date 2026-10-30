
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' THEN 
                        CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS Full_Street_Address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS Full_Name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS Total_Sales,
        SUM(ws_quantity) AS Total_Quantity,
        COUNT(DISTINCT ws_order_number) AS Order_Count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.Full_Name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ai.Full_Street_Address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    COALESCE(sd.Total_Sales, 0) AS Total_Sales,
    COALESCE(sd.Total_Quantity, 0) AS Total_Quantity,
    COALESCE(sd.Order_Count, 0) AS Order_Count
FROM 
    CustomerInfo ci
JOIN 
    customer_address ca ON ci.c_customer_sk = ca.ca_address_sk 
LEFT JOIN 
    AddressInfo ai ON ca.ca_address_sk = ai.ca_address_sk
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ci.cd_purchase_estimate > 100
ORDER BY 
    Total_Sales DESC
LIMIT 50;
