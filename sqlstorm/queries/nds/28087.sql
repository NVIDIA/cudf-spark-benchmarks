
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS full_address
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ad.full_address,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerData cd
LEFT JOIN 
    AddressData ad ON cd.c_customer_sk = ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.customer_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' AND sd.total_sales > 1000)
ORDER BY 
    total_sales DESC
LIMIT 100;
