
WITH  employee_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           cd.cd_marital_status, cd.cd_credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
customer_sales AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ranked_sales AS (
    SELECT cs.customer_sk, cs.total_sales, cs.order_count,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
),
top_customers AS (
    SELECT eh.c_first_name, eh.c_last_name, eh.cd_gender, 
           rs.total_sales, 
           COALESCE(rs.order_count, 0) AS order_count
    FROM employee_hierarchy eh
    LEFT JOIN ranked_sales rs ON eh.c_customer_sk = rs.customer_sk
    WHERE eh.rn <= 10
),
customer_address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, 
           ca.ca_zip, ca.ca_country
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
),
final_report AS (
    SELECT tc.c_first_name, tc.c_last_name, 
           tc.cd_gender, tc.total_sales, 
           tc.order_count, 
           ca.ca_city, ca.ca_state, 
           ca.ca_zip, ca.ca_country,
           ROW_NUMBER() OVER (ORDER BY tc.total_sales DESC) AS report_rank
    FROM top_customers tc
    LEFT JOIN customer_address_info ca ON tc.c_first_name = ca.ca_city
)
SELECT *
FROM final_report
WHERE report_rank <= 10
ORDER BY total_sales DESC;
