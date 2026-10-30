
WITH Address_Credentials AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city, 
        ca_state
    FROM 
        customer_address
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate, 
        cd_credit_rating, 
        cd_dep_count, 
        cd_dep_employed_count, 
        cd_dep_college_count
    FROM 
        customer_demographics
),
Sales_Data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_sales_price) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    addr.full_address, 
    addr.ca_city, 
    addr.ca_state,
    dem.cd_gender, 
    dem.cd_marital_status, 
    dem.cd_education_status, 
    dem.cd_purchase_estimate, 
    sales.total_quantity_sold, 
    sales.total_sales_value
FROM 
    Address_Credentials addr
JOIN 
    customer c ON c.c_current_addr_sk = addr.ca_address_sk
JOIN 
    Customer_Demographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
LEFT JOIN 
    Sales_Data sales ON c.c_customer_sk = sales.ws_item_sk
WHERE 
    addr.ca_state = 'CA' 
    AND dem.cd_marital_status = 'M'
    AND dem.cd_purchase_estimate > 5000
ORDER BY 
    sales.total_sales_value DESC
LIMIT 100;
