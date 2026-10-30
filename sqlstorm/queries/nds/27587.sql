
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ', ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ca.ca_city,
        ca.ca_state,
        sd.total_sales,
        sd.order_count,
        rc.rnk
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CustomerAddresses ca ON rc.c_customer_sk = ca.c_customer_sk
    LEFT JOIN 
        SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cm.c_first_name,
    cm.c_last_name,
    cm.ca_city,
    cm.ca_state,
    cm.total_sales,
    cm.order_count
FROM 
    CustomerMetrics cm
WHERE 
    cm.rnk <= 5
ORDER BY 
    cm.total_sales DESC;
