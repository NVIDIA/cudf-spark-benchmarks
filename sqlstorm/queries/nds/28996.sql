
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city AS address_city, 
        ca.ca_state AS address_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate 
    FROM 
        customer c 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS total_orders 
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name, 
        cd.address_city, 
        cd.address_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        sd.total_sales, 
        sd.total_orders 
    FROM 
        CustomerDetails cd 
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
)
SELECT 
    address_city, 
    address_state, 
    COUNT(*) AS female_married_count, 
    AVG(total_sales) AS avg_sales_per_customer, 
    SUM(total_orders) AS total_orders_by_female_married 
FROM 
    CombinedData 
GROUP BY 
    address_city, 
    address_state 
ORDER BY 
    female_married_count DESC;
