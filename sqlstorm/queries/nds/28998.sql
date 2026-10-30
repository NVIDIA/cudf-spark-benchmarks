
WITH CombinedAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS TotalSpent,
        COUNT(ws.ws_order_number) AS TotalOrders,
        MAX(d.d_date) AS LastPurchaseDate
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cd.FullName,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ca.FullAddress,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    rs.TotalSpent,
    rs.TotalOrders,
    rs.LastPurchaseDate
FROM CustomerDetails cd
JOIN CombinedAddress ca ON cd.c_customer_sk = ca.ca_address_sk
LEFT JOIN RecentSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
WHERE cd.cd_purchase_estimate > 1000
ORDER BY rs.TotalSpent DESC, rs.LastPurchaseDate DESC
LIMIT 100;
