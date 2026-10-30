
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        EXTRACT(HOUR FROM TIMESTAMP '2002-10-01 12:34:56') AS current_hour,
        (SELECT COUNT(*)
         FROM store_sales ss
         WHERE ss.ss_customer_sk = c.c_customer_sk) AS purchase_count,
        (SELECT COUNT(*)
         FROM web_sales ws
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS online_purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_education_status = 'Bachelor'
),
RankedCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (PARTITION BY ca_state ORDER BY purchase_count DESC) AS state_rank,
        RANK() OVER (PARTITION BY ca_city ORDER BY online_purchase_count DESC) AS city_rank
    FROM 
        CustomerStats c
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    purchase_count,
    online_purchase_count,
    current_hour,
    state_rank,
    city_rank
FROM 
    RankedCustomers
WHERE 
    state_rank <= 5 OR city_rank <= 5
ORDER BY 
    ca_state, purchase_count DESC, online_purchase_count DESC;
