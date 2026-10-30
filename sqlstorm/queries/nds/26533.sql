
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address 
    LEFT JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_address_sk, ca_street_number, ca_street_name, ca_street_type, ca_suite_number, 
        ca_city, ca_state, ca_zip
),
DemographicsSummary AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT customer.c_customer_sk) AS demographics_count
    FROM 
        customer 
    INNER JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SaleStatistics AS (
    SELECT 
        ws_bill_addr_sk, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    COALESCE(d.demographics_count, 0) AS demographics_total,
    COALESCE(s.total_sales, 0) AS total_sales_value,
    COALESCE(s.total_net_paid, 0) AS total_net_paid_value,
    a.customer_count
FROM 
    AddressDetails a
LEFT JOIN 
    DemographicsSummary d ON a.customer_count > 0
LEFT JOIN 
    SaleStatistics s ON s.ws_bill_addr_sk = a.ca_address_sk
ORDER BY 
    total_sales_value DESC, customer_count DESC;
