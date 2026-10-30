
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
order_summary AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
web_order_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(os.total_quantity, 0) AS catalog_quantity,
    COALESCE(os.total_sales, 0) AS catalog_sales,
    COALESCE(wos.total_quantity, 0) AS web_quantity,
    COALESCE(wos.total_sales, 0) AS web_sales,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
FROM 
    customer_info ci
LEFT JOIN 
    order_summary os ON ci.c_customer_sk = os.customer_sk
LEFT JOIN 
    web_order_summary wos ON ci.c_customer_sk = wos.customer_sk
WHERE 
    LOWER(ci.ca_country) = 'canada'
ORDER BY 
    catalog_sales DESC, 
    web_sales DESC;
