
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(INITCAP(ca_street_number), ' ', INITCAP(ca_street_name), ' ', INITCAP(ca_street_type)) AS FullAddress,
        ca_city,
        ca_state
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(INITCAP(c.c_first_name), ' ', INITCAP(c.c_last_name)) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cd.FullName,
    cd.cd_gender,
    ca.FullAddress,
    ca.ca_city,
    ca.ca_state,
    sd.TotalSales,
    sd.OrderCount
FROM CustomerDetails cd
JOIN AddressParts ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE sd.TotalSales > 1000
ORDER BY sd.TotalSales DESC, cd.FullName;
