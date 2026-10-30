
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ss.total_orders,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    CASE
        WHEN ss.total_sales >= 500 THEN 'High Value'
        WHEN ss.total_sales >= 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer_info AS ci
LEFT JOIN 
    sales_summary AS ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND ci.ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    ci.c_last_name, ci.c_first_name;
