
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        CustomerStats cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.cd_marital_status
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
)

SELECT 
    t.c_customer_sk, 
    t.c_first_name, 
    t.c_last_name, 
    COALESCE(t.total_sales, 0) AS total_sales,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers t
LEFT JOIN 
    customer_address ca ON t.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
ORDER BY 
    t.total_sales DESC;
