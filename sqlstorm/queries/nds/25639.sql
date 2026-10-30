
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        case 
            when cd.cd_marital_status = 'M' then 'Married'
            when cd.cd_marital_status = 'S' then 'Single'
            else 'Other'
        end AS marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        SUM(ws.ws_quantity) AS total_items
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_spent, 0.00) AS total_spent,
    COALESCE(ss.total_items, 0) AS total_items,
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_customer_sk = cd.c_customer_sk) AS page_visits,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = cd.c_customer_sk) AS total_returns
FROM customer_details cd
LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY total_spent DESC, cd.full_name ASC
LIMIT 100;
