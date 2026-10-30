
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        c_current_addr_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Total_Orders,
        AVG(ws_net_paid) AS Avg_Net_Paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    CD.c_customer_sk,
    CD.c_first_name,
    CD.c_last_name,
    CD.cd_gender,
    CD.cd_marital_status,
    AD.Full_Address,
    AD.ca_city,
    AD.ca_state,
    AD.ca_zip,
    SD.Total_Sales,
    SD.Total_Orders,
    SD.Avg_Net_Paid
FROM 
    CustomerDetails CD
LEFT JOIN 
    AddressDetails AD ON CD.c_current_addr_sk = AD.ca_address_sk
LEFT JOIN 
    SalesData SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
WHERE 
    CD.cd_gender = 'F' AND
    CD.cd_education_status LIKE '%College%'
ORDER BY 
    SD.Total_Sales DESC
LIMIT 100;
