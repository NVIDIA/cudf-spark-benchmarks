
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(CASE WHEN cd.cd_credit_rating IS NULL THEN 'Unknown' ELSE cd.cd_credit_rating END) AS credit_rating,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales_count,
        SUM(s.ss_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
return_data AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(ss.total_sales) AS total_sales,
        COALESCE(SUM(rs.total_returned), 0) AS total_returns,
        SUM(ss.total_sales) - COALESCE(SUM(rs.total_returned), 0) AS net_sales
    FROM customer_data cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
    LEFT JOIN return_data rs ON ss.ws_item_sk = rs.sr_item_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 0 THEN 'Profitable' 
        ELSE 'Non-Profitable' 
    END AS profitability_status,
    ROW_NUMBER() OVER (ORDER BY f.net_sales DESC) AS sales_rank
FROM final_summary f
ORDER BY f.net_sales DESC
LIMIT 100;
