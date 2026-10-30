
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
high_value_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.gender_rank <= 10
),
sales_data AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_net_paid,
        s.ss_ext_sales_price,
        c.c_customer_sk
    FROM 
        store_sales s
    JOIN 
        high_value_customers c ON s.ss_customer_sk = c.c_customer_sk
)
SELECT 
    d.d_date,
    SUM(sd.ss_quantity) AS total_quantity_sold,
    SUM(sd.ss_net_paid) AS total_net_sales,
    AVG(sd.ss_ext_sales_price) AS average_sales_price,
    COUNT(DISTINCT sd.c_customer_sk) AS unique_customers,
    CASE 
        WHEN SUM(sd.ss_net_paid) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    sales_data sd
JOIN 
    date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date DESC
LIMIT 30;
