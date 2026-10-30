
WITH Address_City AS (
    SELECT DISTINCT ca_city 
    FROM customer_address 
    WHERE ca_city IS NOT NULL
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        s.total_quantity,
        s.total_sales
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN Sales_Summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE a.ca_city IN (SELECT ca_city FROM Address_City)
)
SELECT 
    CONCAT('Customer Name: ', full_name, 
           ', City: ', ca_city, 
           ', Gender: ', cd_gender, 
           ', Marital Status: ', cd_marital_status,
           ', Purchase Estimate: $', cd_purchase_estimate,
           ', Total Quantity Bought: ', COALESCE(total_quantity, 0),
           ', Total Sales Amount: $', COALESCE(total_sales, 0)) AS Customer_Details
FROM Customer_Info
ORDER BY ca_city, cd_gender, total_sales DESC
LIMIT 100;
