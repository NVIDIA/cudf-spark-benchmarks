
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        d.cd_gender,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_marital_status,
        d.cd_education_status,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(address_length) AS avg_address_length,
        MAX(address_length) AS max_address_length,
        MIN(address_length) AS min_address_length
    FROM 
        AddressData
    GROUP BY 
        ca_state
),
CustomerOrders AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk AS customer_sk,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.ca_state,
    st.total_addresses,
    st.avg_address_length,
    o.total_orders,
    o.total_spent
FROM 
    CustomerData c
JOIN 
    AddressData a ON c.c_customer_id = a.full_address
JOIN 
    AddressStats st ON a.ca_state = st.ca_state
LEFT JOIN 
    CustomerOrders o ON c.c_customer_sk = o.customer_sk
ORDER BY 
    o.total_spent DESC
LIMIT 100;
