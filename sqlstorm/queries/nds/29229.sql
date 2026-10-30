WITH Address_Analysis AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        full_address, ca_city, ca_state
),
Gender_Analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Final_Analysis AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.address_count,
        g.cd_gender,
        g.gender_count,
        s.total_sales,
        s.total_orders,
        s.unique_customers
    FROM 
        Address_Analysis a
    LEFT JOIN 
        Gender_Analysis g ON a.address_count > 1 
    LEFT JOIN 
        Sales_Analysis s ON g.gender_count > 10 
    WHERE 
        a.ca_state = 'NY' 
)
SELECT 
    full_address, 
    ca_city, 
    ca_state, 
    address_count, 
    cd_gender, 
    gender_count, 
    total_sales, 
    total_orders, 
    unique_customers
FROM 
    Final_Analysis
ORDER BY 
    total_sales DESC, unique_customers DESC;