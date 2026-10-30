
WITH BaseData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_date,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        d.d_date
),
RankedCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        ca_country,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_spent,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank
    FROM BaseData
)

SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_spent,
    order_count
FROM RankedCustomers
WHERE rank <= 10
ORDER BY ca_state, total_spent DESC;
