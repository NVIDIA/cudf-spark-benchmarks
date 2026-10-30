
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CompleteReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Spender'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    CompleteReport
ORDER BY 
    total_sales DESC;
