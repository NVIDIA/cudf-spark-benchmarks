
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        ca_city,
        ca_state,
        ca_country
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS Full_Name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalResults AS (
    SELECT 
        cd.Full_Name,
        ad.Full_Address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        cs.Total_Sales,
        cs.Order_Count
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesSummary cs ON cd.c_customer_sk = cs.ws_bill_customer_sk
)

SELECT 
    *,
    CASE 
        WHEN Total_Sales > 1000 THEN 'High Value'
        WHEN Total_Sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value
FROM 
    FinalResults
ORDER BY 
    Total_Sales DESC;
