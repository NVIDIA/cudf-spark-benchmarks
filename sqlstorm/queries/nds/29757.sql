
WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        DENSE_RANK() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_education_status LIKE '%Graduate%' THEN 'Graduate'
            WHEN cd_education_status LIKE '%Undergraduate%' THEN 'Undergraduate'
            ELSE 'Other'
        END AS education_category,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_orders,
        AVG(ws_sales_price) AS avg_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        d.cd_gender,
        d.education_category,
        s.total_sales,
        s.number_of_orders,
        s.avg_sales_value,
        a.address_rank
    FROM 
        customer c
    JOIN AddressAnalysis a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        d.cd_marital_status = 'M' AND 
        (d.cd_gender = 'F' OR d.cd_gender = 'M')
)
SELECT 
    customer_name,
    full_address,
    cd_gender,
    education_category,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(number_of_orders, 0) AS number_of_orders,
    COALESCE(avg_sales_value, 0.00) AS avg_sales_value
FROM 
    CustomerAnalysis
WHERE 
    address_rank = 1
ORDER BY 
    total_sales DESC
LIMIT 10;
