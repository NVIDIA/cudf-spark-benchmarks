
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
final_summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_country,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ss.total_sales,
        ss.order_count,
        CASE 
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            WHEN ss.total_sales > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    customer_type
FROM 
    final_summary
ORDER BY 
    total_sales DESC, 
    order_count DESC
LIMIT 100;
