
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS FullName,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(ws_order_number) AS NumberOfOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.FullName,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    COALESCE(sd.TotalSales, 0) AS TotalSales,
    COALESCE(sd.NumberOfOrders, 0) AS NumberOfOrders
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND ad.ca_state = 'CA' 
    AND cd.cd_purchase_estimate > 1000
ORDER BY 
    TotalSales DESC, 
    cd.FullName ASC;
