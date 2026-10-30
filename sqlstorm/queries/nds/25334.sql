
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CompleteReport AS (
    SELECT 
        Cust.full_name,
        Cust.cd_gender,
        Cust.cd_marital_status,
        Cust.cd_education_status,
        Addr.full_address,
        Addr.ca_city,
        Addr.ca_state,
        Addr.ca_zip,
        Addr.ca_country,
        COALESCE(Sales.total_sales, 0) AS total_sales,
        COALESCE(Sales.total_orders, 0) AS total_orders
    FROM 
        CustomerDetails Cust
    LEFT JOIN 
        AddressDetails Addr ON Cust.c_customer_sk = Addr.ca_address_sk
    LEFT JOIN 
        SalesDetails Sales ON Cust.c_customer_sk = Sales.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    CompleteReport
ORDER BY 
    total_sales DESC, full_name;
