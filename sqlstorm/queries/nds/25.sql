
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
), 
ranked_customers AS (
    SELECT 
        ci.*,
        ss.total_orders,
        ss.total_profit,
        ss.avg_order_value,
        RANK() OVER (PARTITION BY ci.d_month_seq ORDER BY ss.total_profit DESC) AS profit_rank
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    COALESCE(rc.total_orders, 0) AS total_orders,
    COALESCE(rc.total_profit, 0) AS total_profit,
    COALESCE(rc.avg_order_value, 0) AS avg_order_value,
    CASE 
        WHEN rc.cd_marital_status = 'S' THEN 'Single'
        WHEN rc.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Other'
    END AS marital_status_desc,
    CASE 
        WHEN rc.profit_rank IS NULL THEN 'No Sales'
        WHEN rc.profit_rank <= 10 THEN 'Top Performing Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM ranked_customers rc
WHERE rc.profit_rank <= 10 OR rc.total_orders IS NULL
ORDER BY rc.d_month_seq, rc.total_profit DESC;
