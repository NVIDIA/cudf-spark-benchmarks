WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
SalesData AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS unique_orders,
        w_city,
        w_state
    FROM 
        web_sales
    JOIN 
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    GROUP BY 
        w_city, w_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.full_address,
    a.address_count,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.customer_count,
    s.total_sales,
    s.unique_orders
FROM 
    AddressInfo a
JOIN 
    CustomerInfo c ON a.ca_city = c.cd_gender 
JOIN 
    SalesData s ON a.ca_city = s.w_city AND a.ca_state = s.w_state
ORDER BY 
    a.ca_city, a.ca_state, c.customer_count DESC;