
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', c.c_first_name) 
            WHEN cd.cd_gender = 'F' THEN CONCAT('Ms. ', c.c_first_name) 
            ELSE c.c_first_name 
        END AS salutation
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), PurchaseSummary AS (
    SELECT 
        cd.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.c_customer_sk
), StringProcessing AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        ps.total_orders,
        ps.total_spent,
        LENGTH(cd.full_name) AS name_length,
        LENGTH(cd.ca_city) AS city_length,
        LENGTH(cd.ca_state) AS state_length
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        PurchaseSummary ps ON cd.c_customer_sk = ps.c_customer_sk
)
SELECT 
    sp.full_name,
    sp.ca_city,
    sp.ca_state,
    sp.total_orders,
    sp.total_spent,
    sp.name_length,
    sp.city_length,
    sp.state_length,
    CHAR_LENGTH(sp.full_name) AS char_length,
    UPPER(sp.ca_city) AS city_in_uppercase,
    LOWER(sp.full_name) AS name_in_lowercase,
    INITCAP(sp.ca_state) AS state_in_initial_capital
FROM 
    StringProcessing sp
WHERE 
    sp.total_spent > 1000
ORDER BY 
    sp.total_spent DESC;
