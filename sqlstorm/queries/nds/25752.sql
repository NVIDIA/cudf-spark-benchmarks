
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_revenue,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
final_summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.c_email_address,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_revenue, 0.00) AS total_revenue,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0.00) AS total_return_amount
    FROM customer_details cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN return_summary rs ON cd.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT
    *,
    (total_revenue - total_return_amount) AS net_revenue,
    (total_orders - total_returns) AS net_orders
FROM final_summary
ORDER BY net_revenue DESC
LIMIT 100;
