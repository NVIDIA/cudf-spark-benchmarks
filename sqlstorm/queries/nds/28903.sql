
WITH CustomerFullInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cfi.full_name,
        cfi.ca_city,
        cfi.ca_state,
        cfi.cd_gender,
        cfi.cd_marital_status,
        cfi.cd_purchase_estimate,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_sales_price
    FROM CustomerFullInfo cfi
    LEFT JOIN SalesStats ss ON cfi.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(avg_sales_price, 0.0) AS avg_sales_price
FROM FinalReport
WHERE cd_purchase_estimate > 10000
ORDER BY total_sales DESC
LIMIT 100;
