
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        sv.total_sales,
        sv.order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary sv ON c.c_customer_sk = sv.ws_bill_customer_sk
), active_customers AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cd.total_sales, 0) AS total_sales,
        COALESCE(cd.order_count, 0) AS order_count,
        RANK() OVER (ORDER BY COALESCE(cd.total_sales, 0) DESC) AS customer_rank
    FROM 
        customer_details cd
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'S'
), high_value_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales >= 1000 THEN 'High Value'
            WHEN total_sales >= 500 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        active_customers
    WHERE 
        customer_rank <= 10
)
SELECT 
    a.c_customer_id,
    a.c_first_name,
    a.c_last_name,
    a.cd_gender,
    a.customer_value,
    a.total_sales
FROM 
    high_value_customers a
ORDER BY 
    a.total_sales DESC
LIMIT 20;
