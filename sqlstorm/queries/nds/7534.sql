
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458853 AND 2459489  
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_dep_count,
        cd_purchase_estimate,
        rs.total_sales,
        rs.order_count,
        rs.ws_bill_customer_sk
    FROM RankedSales rs
    JOIN customer c ON c.c_customer_sk = rs.ws_bill_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE rs.sales_rank <= 10  
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(tc.total_sales) AS total_sales,
    AVG(tc.order_count) AS avg_orders_per_customer,
    COUNT(DISTINCT tc.ws_bill_customer_sk) AS customer_count,
    MIN(tc.cd_purchase_estimate) AS min_purchase_estimate,
    MAX(tc.cd_purchase_estimate) AS max_purchase_estimate,
    COUNT(CASE WHEN tc.cd_gender = 'M' THEN 1 END) AS male_customer_count,
    COUNT(CASE WHEN tc.cd_gender = 'F' THEN 1 END) AS female_customer_count
FROM TopCustomers tc
JOIN customer_address ca ON ca.ca_address_sk = tc.ca_address_sk
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_sales DESC
LIMIT 5;
