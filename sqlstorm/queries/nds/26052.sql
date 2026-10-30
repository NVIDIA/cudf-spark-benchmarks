
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
),
DateStats AS (
    SELECT 
        d.d_year,
        COUNT(*) AS active_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        date_dim d
        JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        d.d_year
),
BestCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ds.active_customers,
        ds.avg_purchase_estimate
    FROM 
        CustomerInfo ci
        JOIN DateStats ds ON EXTRACT(YEAR FROM TIMESTAMP '2002-10-01 12:34:56') = ds.d_year
    WHERE 
        ci.city_rank <= 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    active_customers,
    avg_purchase_estimate
FROM 
    BestCustomers
ORDER BY 
    avg_purchase_estimate DESC;
