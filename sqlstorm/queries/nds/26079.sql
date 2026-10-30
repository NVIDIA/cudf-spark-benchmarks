
WITH CustomerFullName AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),

CustomerSalesInfo AS (
    SELECT 
        cfn.full_name,
        cfn.cd_gender,
        cfn.cd_marital_status,
        cfn.cd_education_status,
        cfn.ca_city,
        cfn.ca_state,
        cfn.ca_country,
        sd.total_sales,
        sd.total_profit
    FROM 
        CustomerFullName cfn
    LEFT JOIN 
        SalesData sd ON cfn.c_customer_sk = sd.ws_bill_customer_sk
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_profit, 0) AS total_profit,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    CustomerSalesInfo
ORDER BY 
    total_sales DESC;
