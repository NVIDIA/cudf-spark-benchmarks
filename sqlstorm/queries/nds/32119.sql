
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ss.total_sales,
        ss.order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.customer_sk
), 
address_summary AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_current_addr_sk) AS address_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.order_count, 0) AS order_count,
    COALESCE(as_.address_count, 0) AS address_count,
    CASE 
        WHEN cd.total_sales > 10000 THEN 'High'
        WHEN cd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM customer_details cd
FULL OUTER JOIN address_summary as_ ON cd.c_customer_sk = as_.c_customer_sk
WHERE (cd.cd_gender = 'F' AND cd.order_count > 0) OR (cd.cd_marital_status = 'S' AND as_.address_count > 1)
ORDER BY total_sales DESC, cd.c_last_name, cd.c_first_name
LIMIT 50;
