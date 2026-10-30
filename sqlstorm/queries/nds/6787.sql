WITH aggregated_sales AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_quantity) AS average_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458124 AND 2458754 
    GROUP BY ws_bill_cdemo_sk
),
customer_details AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
),
customer_summary AS (
    SELECT 
        ad.ca_city AS city,
        ad.ca_state AS state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(s.total_net_paid) AS total_spent,
        COUNT(s.order_count) AS order_count,
        AVG(s.average_quantity) AS avg_quantity_per_order
    FROM aggregated_sales s
    JOIN customer_details cd ON s.customer_demo_sk = cd.cd_demo_sk
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    GROUP BY ad.ca_city, ad.ca_state, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    city,
    state,
    cd_gender,
    cd_marital_status,
    total_spent,
    order_count,
    avg_quantity_per_order
FROM customer_summary
WHERE total_spent > 1000
ORDER BY total_spent DESC;