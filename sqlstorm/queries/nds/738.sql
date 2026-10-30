
WITH recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Customer'
        WHEN rs.sales_rank <= 5 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM recent_sales rs
JOIN customer_info ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
WHERE rs.total_sales IS NOT NULL AND 
      ci.cd_credit_rating IN ('Excellent', 'Good')
ORDER BY rs.total_sales DESC 
LIMIT 10;
