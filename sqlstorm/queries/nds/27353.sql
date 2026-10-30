
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_county, ca_state, ca_zip, ca_country) AS full_address,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
) 
SELECT 
    cd.full_name,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ad.full_address,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    ad.street_name_length
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
JOIN 
    AddressDetails ad ON ad.ca_country = 'USA'
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, 
    ad.street_name_length DESC;
