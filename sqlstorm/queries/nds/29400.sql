
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cu.full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerData cu
    LEFT JOIN 
        AddressData ad ON cu.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.total_sales,
    cd.total_orders,
    CASE 
        WHEN cd.total_sales > 5000 THEN 'High Spender'
        WHEN cd.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    CombinedData cd
WHERE 
    cd.ca_state = 'CA'
ORDER BY 
    cd.total_sales DESC
LIMIT 100;
