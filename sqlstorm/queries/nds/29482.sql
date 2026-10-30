
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
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
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ai.full_address,
        ai.city_lower,
        ai.ca_state,
        ai.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerInfo ci
    JOIN 
        customer c ON ci.c_customer_sk = c.c_customer_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    city_lower,
    ca_state,
    AVG(total_sales) AS average_sales,
    COUNT(*) AS customer_count
FROM 
    CombinedInfo
WHERE 
    total_sales > (
        SELECT AVG(total_sales) FROM SalesData
    )
GROUP BY 
    city_lower, ca_state
ORDER BY 
    average_sales DESC;
