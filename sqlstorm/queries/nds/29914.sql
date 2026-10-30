WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit
    FROM 
        web_sales
    WHERE 
        ws_quantity > 2
),
StatisticalSummary AS (
    SELECT 
        COUNT(*) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS average_sales_price
    FROM 
        SalesInfo
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    c.cd_dep_count,
    c.cd_dep_employed_count,
    c.cd_dep_college_count,
    s.total_orders,
    s.total_profit,
    s.average_sales_price
FROM 
    AddressDetails a
JOIN 
    CustomerInfo c ON a.ca_zip = c.cd_credit_rating  
CROSS JOIN 
    StatisticalSummary s
WHERE 
    a.ca_state = 'NY' AND
    c.cd_gender = 'F'
ORDER BY 
    s.total_profit DESC;