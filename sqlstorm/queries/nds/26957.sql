
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        SUM(CASE 
                WHEN ws_sales_price > 100 THEN 1 
                ELSE 0 
            END) AS high_value_sales,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(ws_item_sk) AS total_sales_count
    FROM 
        web_sales
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    sd.high_value_sales,
    sd.average_sales_price,
    sd.total_sales_count
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON cd.cd_purchase_estimate > 5000
CROSS JOIN 
    SalesData sd
WHERE 
    ad.ca_state = 'NY' 
    AND cd.cd_gender = 'F'
GROUP BY 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    sd.high_value_sales,
    sd.average_sales_price,
    sd.total_sales_count
ORDER BY 
    cd.cd_purchase_estimate DESC
LIMIT 50;
