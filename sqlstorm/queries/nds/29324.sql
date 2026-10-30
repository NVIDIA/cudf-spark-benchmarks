
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        c_customer_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
EnhancedSales AS (
    SELECT 
        s.ss_item_sk,
        sa.full_address,
        ci.full_name,
        si.total_orders,
        si.total_revenue
    FROM 
        store_sales s
    JOIN 
        AddressInfo sa ON s.ss_addr_sk = sa.ca_address_sk
    JOIN 
        CustomerInfo ci ON s.ss_customer_sk = ci.c_customer_sk
    JOIN 
        SalesInfo si ON s.ss_item_sk = si.ws_item_sk
)
SELECT 
    full_address,
    full_name,
    total_orders,
    total_revenue
FROM 
    EnhancedSales
WHERE 
    total_revenue > 1000 AND 
    (full_address LIKE '%Main%' OR full_name LIKE '%Smith%')
ORDER BY 
    total_revenue DESC
LIMIT 50;
