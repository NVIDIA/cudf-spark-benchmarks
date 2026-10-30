
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
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
filtered_customer_sales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ci.full_name, ci.cd_gender, ci.cd_marital_status
),
ranked_customers AS (
    SELECT 
        fcs.full_name,
        fcs.cd_gender,
        fcs.cd_marital_status,
        fcs.total_sales,
        fcs.order_count,
        DENSE_RANK() OVER (ORDER BY fcs.total_sales DESC) AS sales_rank
    FROM filtered_customer_sales fcs
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_sales,
    rc.order_count,
    rc.sales_rank
FROM ranked_customers rc
WHERE rc.sales_rank <= 10
ORDER BY rc.sales_rank;
