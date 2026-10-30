
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ss.total_sales,
        ss.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ss.total_sales DESC) AS rank,
        ci.c_customer_sk
    FROM 
        CustomerInfo ci
    JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.c_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.cd_purchase_estimate,
    rc.total_sales,
    rc.total_orders,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country
FROM 
    RankedCustomers rc
JOIN 
    AddressDetails a ON rc.c_customer_sk = a.ca_address_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, rc.total_sales DESC;
