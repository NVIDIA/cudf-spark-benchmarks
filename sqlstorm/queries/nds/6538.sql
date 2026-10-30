
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.total_quantity,
        c.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.d_year ORDER BY c.total_net_paid DESC) AS rn
    FROM 
        CustomerData c
)
SELECT 
    tc.customer_id,
    tc.total_quantity,
    tc.total_net_paid,
    ca.ca_city AS city,
    ca.ca_state AS state,
    ca.ca_county AS county,
    ca.ca_country AS country
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.customer_id = ca.ca_address_id
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.rn <= 5
ORDER BY 
    tc.total_net_paid DESC;
