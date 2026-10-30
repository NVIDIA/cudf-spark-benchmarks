
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        SUM(sd.total_sales) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
),
ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_credit_rating,
        c.total_sales,
        DENSE_RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        customer_data c
)
SELECT 
    rc.cd_gender,
    COUNT(*) AS customer_count,
    AVG(rc.total_sales) AS average_sales,
    SUM(rc.total_sales) AS total_sales_sum
FROM 
    ranked_customers rc
WHERE 
    rc.sales_rank <= 10
GROUP BY 
    rc.cd_gender
ORDER BY 
    rc.cd_gender;
