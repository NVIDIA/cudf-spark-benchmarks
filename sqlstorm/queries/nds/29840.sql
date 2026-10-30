
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        LENGTH(c.c_email_address) AS email_length,
        (SELECT COUNT(*) 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'NY') AND cd.cd_gender = 'F'
), RankedCustomers AS (
    SELECT 
        ci.*,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY ci.total_web_sales DESC) AS rank
    FROM CustomerInfo ci
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    total_web_sales, 
    email_length
FROM RankedCustomers
WHERE rank <= 5
ORDER BY ca_state, total_web_sales DESC;
