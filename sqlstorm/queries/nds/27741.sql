
WITH AddressCTE AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerCTE AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c_birth_year,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        c_email_address,
        c_customer_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    CONCAT(c.full_name, ' (', c.cd_gender, ')') AS customer_name,
    a.ca_city,
    a.ca_state,
    a.full_address,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(s.total_sales, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(s.total_sales, 0) < 100 THEN 'Low Sales'
        WHEN COALESCE(s.total_sales, 0) BETWEEN 100 AND 500 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    AddressCTE a
JOIN 
    CustomerCTE c ON c.c_email_address LIKE '%@example.com'
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    s.total_sales DESC;
