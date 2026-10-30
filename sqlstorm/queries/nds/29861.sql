
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        LENGTH(c.c_email_address) > 10
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating, ca.ca_city, ca.ca_state
),
TopCustomers AS (
    SELECT 
        full_name,
        total_orders,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rnk
    FROM 
        CustomerInfo
)
SELECT 
    full_name,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    TopCustomers
WHERE 
    rnk <= 10
ORDER BY 
    total_spent DESC;
