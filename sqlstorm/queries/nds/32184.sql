
WITH  date_range AS (
    SELECT MIN(d_date_sk) AS start_date_sk, MAX(d_date_sk) AS end_date_sk
    FROM date_dim
    WHERE d_year = 2023
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown' 
            ELSE cd.cd_credit_rating 
        END AS credit_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws.ws_sold_date_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
),
returns_summary AS (
    SELECT sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns sr
    GROUP BY sr_returned_date_sk
),
final_summary AS (
    SELECT dd.d_date AS sale_date, 
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_revenue, 0) AS total_revenue,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        (COALESCE(ss.total_revenue, 0) - COALESCE(rs.total_returned_amount, 0)) AS net_revenue
    FROM date_dim dd
    LEFT JOIN sales_summary ss ON dd.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN returns_summary rs ON dd.d_date_sk = rs.sr_returned_date_sk
    WHERE dd.d_year = 2023
)
SELECT f.sale_date, 
       f.total_quantity,
       f.total_revenue,
       f.total_returned_quantity,
       f.total_returned_amount,
       f.net_revenue,
       ci.c_first_name, 
       ci.c_last_name, 
       ci.credit_status
FROM final_summary f
JOIN customer_info ci ON ci.rank <= 10
WHERE f.total_revenue > 1000
ORDER BY f.sale_date, f.net_revenue DESC
LIMIT 100;
