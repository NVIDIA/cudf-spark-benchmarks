
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        cd_demo_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_demo_sk
),
SalesSummaries AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ws_ship_addr_sk
    FROM 
        web_sales
    GROUP BY 
        ws_ship_addr_sk
),
Combined AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        dm.cd_gender,
        dm.cd_marital_status,
        ss.total_sales,
        ss.average_sales_price,
        ss.order_count
    FROM 
        AddressDetails ad
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        DemographicDetails dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
    LEFT JOIN 
        SalesSummaries ss ON c.c_current_addr_sk = ss.ws_ship_addr_sk
)
SELECT 
    ca_city, 
    ca_state, 
    COUNT(*) AS total_customers, 
    SUM(total_sales) AS total_sales,
    AVG(average_sales_price) AS avg_sales_price
FROM 
    Combined
GROUP BY 
    ca_city, 
    ca_state
ORDER BY 
    total_sales DESC;
