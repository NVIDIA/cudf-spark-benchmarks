
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnsInfo AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(si.total_spent, 0) AS total_spent,
    COALESCE(si.order_count, 0) AS order_count,
    COALESCE(ri.total_returned, 0) AS total_returned,
    COALESCE(ri.return_count, 0) AS return_count,
    CASE 
        WHEN COALESCE(si.total_spent, 0) > 0 THEN 
            ROUND((COALESCE(ri.total_returned, 0) / COALESCE(si.total_spent, 0)) * 100, 2)
        ELSE 0 
    END AS return_percentage
FROM CustomerInfo ci
LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.customer_sk
LEFT JOIN ReturnsInfo ri ON ci.c_customer_sk = ri.customer_sk
ORDER BY return_percentage DESC;
