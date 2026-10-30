
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Analysis AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(sd.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.customer_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT a.full_name) AS number_of_customers,
    AVG(a.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(a.total_sales) AS total_sales_amount,
    COUNT(a.customer_value_category) AS customer_value_count,
    a.customer_value_category
FROM 
    Analysis a
JOIN 
    customer_address ca ON a.ca_city = ca.ca_city AND a.ca_state = ca.ca_state
GROUP BY 
    ca.ca_city, ca.ca_state, a.customer_value_category
ORDER BY 
    ca.ca_city, ca.ca_state, customer_value_count DESC;
