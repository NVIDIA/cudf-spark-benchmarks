
WITH CustomerAddressCTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographicsCTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUBSTRING(cd_education_status, 1, 3) AS edu_short, 
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_status
    FROM 
        customer_demographics
),
SalesDataCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedCTE AS (
    SELECT 
        ca.ca_address_sk,
        cd.cd_gender,
        cd.edu_short,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        ca.full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS complete_location
    FROM 
        CustomerAddressCTE ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographicsCTE cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        SalesDataCTE sd ON sd.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    ca_address_sk,
    cd_gender,
    edu_short,
    total_sales,
    order_count,
    full_address,
    complete_location,
    CASE 
        WHEN total_sales = 0 THEN 'No Sales'
        WHEN total_sales < 1000 THEN 'Low Sales'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    LENGTH(full_address) AS address_length
FROM 
    CombinedCTE
WHERE 
    cd_gender = 'F' AND 
    LENGTH(full_address) > 50
ORDER BY 
    total_sales DESC, complete_location;
