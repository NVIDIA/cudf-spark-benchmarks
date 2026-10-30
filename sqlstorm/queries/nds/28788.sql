
WITH AddressDetails AS (
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
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        cd.c_customer_sk,
        CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        customer_address ca ON cd.c_customer_sk = ca.ca_address_sk 
    LEFT JOIN 
        AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_sales,
    CASE 
        WHEN total_sales = 0 THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Sales'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    AggregatedData
ORDER BY 
    total_sales DESC
LIMIT 100;
