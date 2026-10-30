
WITH CustomerAddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_county, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
Demographics AS (
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
WeeklySales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_ship_date_sk) AS total_shipped_days
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FullReport AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        ws.total_net_sales,
        ws.total_orders,
        ws.total_shipped_days
    FROM 
        customer c
    JOIN 
        CustomerAddressConcat ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        WeeklySales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    full_address,
    COUNT(*) AS customer_count,
    AVG(total_net_sales) AS average_sales,
    AVG(total_orders) AS average_orders,
    AVG(total_shipped_days) AS average_shipped_days,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    FullReport
GROUP BY 
    full_address, cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    customer_count DESC, average_sales DESC
LIMIT 100;
