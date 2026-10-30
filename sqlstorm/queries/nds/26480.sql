
WITH AddressData AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
DemographicsData AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        LEAST(COALESCE(cd_purchase_estimate, 0), 1000) AS adjusted_purchase_estimate
    FROM 
        customer_demographics
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
) 
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    COALESCE(s.total_sales, 0) AS total_sales_value,
    s.order_count,
    CASE 
        WHEN d.adjusted_purchase_estimate < 500 THEN 'Low'
        WHEN d.adjusted_purchase_estimate BETWEEN 500 AND 750 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_category
FROM 
    AddressData a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    DemographicsData d ON d.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    SalesData s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    a.ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    total_sales_value DESC, 
    a.ca_city ASC;
