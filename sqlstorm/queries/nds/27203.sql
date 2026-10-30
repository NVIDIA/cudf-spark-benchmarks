
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS count_ville_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.count_ville_cities,
        d.cd_gender,
        d.total_customers,
        d.avg_purchase_estimate,
        s.total_sales,
        s.total_orders
    FROM 
        AddressStats a
    JOIN 
        DemographicStats d ON d.total_customers > 100
    LEFT JOIN 
        SalesData s ON s.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IS NOT NULL)
)
SELECT 
    ca_state,
    total_addresses,
    avg_street_name_length,
    count_ville_cities,
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    FinalReport
ORDER BY 
    ca_state, cd_gender;
