
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price - ws_ext_discount_amt) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price - ws_ext_discount_amt) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (ORDER BY c.c_customer_sk) AS row_num
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    s.total_sales,
    s.order_count,
    s.avg_net_paid
FROM 
    customer_info ci
JOIN 
    sales_data s ON ci.c_customer_sk = s.customer_id
WHERE 
    ci.row_num <= 100
    AND (ci.cd_gender = 'F' OR (ci.cd_marital_status = 'M' AND ci.cd_purchase_estimate > 1000))
ORDER BY 
    s.total_sales DESC
LIMIT 50;
