
WITH Address_CTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
Customer_CTE AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
Web_Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    COALESCE(w.total_sales, 0) AS total_sales,
    COALESCE(w.order_count, 0) AS order_count
FROM 
    Customer_CTE c
JOIN 
    Address_CTE a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    Web_Sales_CTE w ON c.c_customer_sk = w.ws_bill_customer_sk
WHERE 
    c.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC;
