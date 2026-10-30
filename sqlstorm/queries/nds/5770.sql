
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_paid) AS total_sales_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
popular_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ss.ss_quantity) AS total_sold
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_sold DESC
    LIMIT 10
),
top_customers AS (
    SELECT 
        c_data.c_customer_id,
        c_data.c_first_name,
        c_data.c_last_name,
        c_data.total_sales_quantity,
        c_data.total_sales_value,
        pi.total_sold
    FROM 
        customer_data c_data
    JOIN 
        popular_items pi ON c_data.total_sales_quantity > 0
    ORDER BY 
        c_data.total_sales_value DESC
    LIMIT 5
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales_quantity,
    tc.total_sales_value,
    pi.i_item_id,
    pi.i_item_desc,
    pi.total_sold
FROM 
    top_customers tc
CROSS JOIN 
    popular_items pi;
