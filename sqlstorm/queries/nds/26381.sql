
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS sales_count
    FROM store_sales s
    GROUP BY s.ss_customer_sk
),
customer_benchmark AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.ca_city,
        rc.ca_state,
        rc.ca_country,
        ss.total_sales,
        ss.sales_count,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High Value'
            WHEN ss.total_sales >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM ranked_customers rc
    LEFT JOIN sales_summary ss ON rc.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    cd_gender, 
    customer_segment, 
    COUNT(*) AS customer_count, 
    AVG(total_sales) AS avg_sales, 
    SUM(total_sales) AS total_sales
FROM customer_benchmark
GROUP BY cd_gender, customer_segment
ORDER BY cd_gender, customer_segment;
