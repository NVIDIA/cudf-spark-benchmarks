
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(cd.cd_demo_sk, '-', c.c_customer_sk) AS demo_identifier
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
return_summary AS (
    SELECT 
        cr_returning_customer_sk AS customer_sk,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
final_report AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(rs.return_count, 0) AS return_count,
        cd.demo_identifier
    FROM 
        customer_details cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_sk = ss.customer_sk
    LEFT JOIN 
        return_summary rs ON cd.c_customer_sk = rs.customer_sk
)

SELECT 
    full_name,
    ca_city,
    ca_state,
    total_sales,
    order_count,
    return_count,
    demo_identifier
FROM 
    final_report
WHERE 
    total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
