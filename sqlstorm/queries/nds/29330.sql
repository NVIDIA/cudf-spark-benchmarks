
WITH Address_Details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Street_Address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Customer_Summary AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS Full_Name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cs.Full_Name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.Total_Sales,
    ss.Order_Count,
    ad.Full_Street_Address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip
FROM Customer_Summary cs
JOIN Sales_Summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
JOIN Address_Details ad ON cs.c_customer_sk = ad.ca_address_sk
WHERE ss.Total_Sales IS NOT NULL
ORDER BY ss.Total_Sales DESC
LIMIT 100;
