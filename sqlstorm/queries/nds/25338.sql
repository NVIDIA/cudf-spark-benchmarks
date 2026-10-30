
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS Total_Sales
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
DetailedSales AS (
    SELECT 
        ci.Full_Name,
        ai.Full_Address,
        si.Total_Sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesData si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    Full_Name,
    Full_Address,
    COALESCE(Total_Sales, 0) AS Total_Sales,
    CASE 
        WHEN Total_Sales IS NULL THEN 'No Sales'
        WHEN Total_Sales < 100 THEN 'Low Value Customer'
        WHEN Total_Sales BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS Customer_Value_Category
FROM 
    DetailedSales
ORDER BY 
    Total_Sales DESC;
