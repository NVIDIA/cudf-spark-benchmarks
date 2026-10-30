
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX') AND cd.cd_marital_status = 'M'
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.full_name,
        c.rn,
        SUM(ds.total_sales) AS total_sales
    FROM 
        customer_info c
    JOIN 
        daily_sales ds ON c.rn = 1  
    GROUP BY 
        c.c_customer_id, c.full_name, c.rn
)
SELECT 
    rc.full_name,
    rc.total_sales,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.cd_gender,
    ci.cd_marital_status,
    ROW_NUMBER() OVER (ORDER BY rc.total_sales DESC) AS sales_rank
FROM 
    ranked_customers rc
JOIN 
    customer_info ci ON rc.c_customer_id = ci.c_customer_id
WHERE 
    rc.total_sales > 1000
ORDER BY 
    sales_rank;
