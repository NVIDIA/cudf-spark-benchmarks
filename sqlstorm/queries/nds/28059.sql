
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
),
FormattedDetails AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        full_address,
        CONCAT('Customer ID: ', c_customer_id, ' | Orders: ', order_count, ' | Total Spent: $', ROUND(total_spent, 2)) AS summary,
        total_spent
    FROM 
        CustomerDetails
    WHERE 
        total_spent > 1000
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    summary,
    CASE 
        WHEN cd_gender = 'M' THEN CONCAT('Mr. ', SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1))
        ELSE CONCAT('Ms. ', SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1))
    END AS formatted_name
FROM 
    FormattedDetails
ORDER BY 
    total_spent DESC
LIMIT 10;
