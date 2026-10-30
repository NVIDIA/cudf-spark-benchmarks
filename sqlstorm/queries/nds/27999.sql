
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_gmt_offset
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS Gender,
        cd_marital_status AS MaritalStatus,
        cd_education_status AS EducationStatus,
        cd_purchase_estimate AS PurchaseEstimate
    FROM customer_demographics
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        a.FullAddress,
        a.ca_city,
        a.ca_state,
        d.Gender,
        d.MaritalStatus,
        d.EducationStatus,
        d.PurchaseEstimate
    FROM customer c
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_sales_price) AS TotalSpent
    FROM web_sales ws
    JOIN CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.FullAddress,
    ci.ca_city,
    ci.ca_state,
    ci.Gender,
    ci.MaritalStatus,
    ci.EducationStatus,
    ss.TotalOrders,
    ss.TotalSpent,
    CASE 
        WHEN ss.TotalSpent >= 1000 THEN 'High Spending'
        WHEN ss.TotalSpent BETWEEN 500 AND 999 THEN 'Medium Spending'
        ELSE 'Low Spending'
    END AS SpendingCategory
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.c_customer_sk
ORDER BY ci.c_last_name, ci.c_first_name;
