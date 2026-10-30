
WITH AddressData AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_item_price
    FROM 
        web_sales
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sd.total_sales,
    sd.total_orders,
    sd.avg_item_price
FROM 
    AddressData ad
JOIN 
    CustomerData cd ON ad.ca_state = cd.cd_credit_rating  
JOIN 
    SalesData sd ON sd.total_sales > 1000  
WHERE 
    ad.ca_zip LIKE '9%'  
GROUP BY 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sd.total_sales,
    sd.total_orders,
    sd.avg_item_price
ORDER BY 
    cd.cd_purchase_estimate DESC, sd.total_sales DESC
LIMIT 100;
