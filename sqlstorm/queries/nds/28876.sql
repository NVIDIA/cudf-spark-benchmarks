
WITH Address_Full AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
Customer_Full AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Full ad ON c.c_current_addr_sk = ad.ca_address_sk
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.full_address,
    c.ca_city,
    c.ca_state,
    cs.total_spent,
    cs.order_count
FROM 
    Customer_Full c
LEFT JOIN 
    Sales_Summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
WHERE 
    c.cd_gender = 'F' 
    AND c.cd_marital_status = 'M' 
    AND cs.total_spent > 500
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
