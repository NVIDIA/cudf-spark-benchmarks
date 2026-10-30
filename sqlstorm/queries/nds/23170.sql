
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(ca.ca_street_number, ''), 'N/A') AS formatted_street_number,
        ca.ca_street_name
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
),
recent_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_customer_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS number_of_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
final_summary AS (
    SELECT 
        rc.c_customer_id, 
        rc.cd_gender,
        aa.ca_city,
        aa.ca_state,
        COALESCE(rr.total_returned_quantity, 0) AS total_returns,
        ss.total_net_profit,
        ss.number_of_orders,
        rc.purchase_rank
    FROM ranked_customers rc
    LEFT JOIN address_details aa ON rc.c_customer_sk = aa.ca_address_sk
    LEFT JOIN recent_returns rr ON rc.c_customer_sk = rr.sr_customer_sk
    LEFT JOIN sales_summary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.ca_city,
    f.ca_state,
    f.total_returns,
    COALESCE(f.total_net_profit, 0) AS total_net_profit,
    f.number_of_orders,
    CASE 
        WHEN f.purchase_rank IS NULL THEN 'New Customer'
        ELSE 'Established Customer'
    END AS customer_status,
    CASE 
        WHEN f.total_returns > 10 THEN 'Frequent Returner'
        ELSE 'Rare Returner'
    END AS returner_type
FROM final_summary f
WHERE f.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_summary)
AND f.number_of_orders > 0
ORDER BY f.total_net_profit DESC, f.number_of_orders
LIMIT 100;
