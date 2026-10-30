
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(UPPER(c.c_first_name), ' ', LOWER(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), CombinedInfo AS (
    SELECT 
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.ca_city,
    ci.ca_state,
    ci.total_sales,
    ci.total_orders,
    CASE 
        WHEN ci.total_sales = 0 THEN 'No Sales'
        WHEN ci.total_sales < 100 THEN 'Low Sales'
        WHEN ci.total_sales BETWEEN 100 AND 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    LENGTH(ci.customer_name) AS name_length,
    (SELECT COUNT(*) FROM customer WHERE c_first_name = SUBSTRING(ci.customer_name, 1, POSITION(' ' IN ci.customer_name) - 1)) AS first_name_count
FROM 
    CombinedInfo ci
ORDER BY 
    ci.total_sales DESC, ci.customer_name;
