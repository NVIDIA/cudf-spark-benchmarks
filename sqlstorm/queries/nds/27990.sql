
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_customer_sk) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price) AS total_sales
FROM 
    RankedCustomers rc
JOIN 
    web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    rc.rank <= 100 AND
    rc.ca_state = 'CA' 
GROUP BY 
    full_name, cd_gender, cd_marital_status
ORDER BY 
    total_sales DESC 
LIMIT 10;
