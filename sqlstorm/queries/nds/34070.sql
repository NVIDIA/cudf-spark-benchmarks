
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number
), customer_details AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        COALESCE(hd_income_band_sk, -1) AS income_band
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
), return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
), joined_sales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.income_band,
        ss.total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        CASE 
            WHEN COALESCE(rs.total_returns, 0) > 0 THEN 'Positive Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM sales_summary ss
    JOIN customer_details c ON ss.ws_item_sk = c.c_customer_sk
    LEFT JOIN return_summary rs ON ss.ws_item_sk = rs.sr_item_sk
    WHERE ss.ranking <= 10
)
SELECT 
    j.c_first_name AS first_name,
    j.c_last_name AS last_name,
    j.income_band,
    j.total_net_profit,
    j.total_returns,
    j.total_returned_amount,
    j.return_status
FROM joined_sales j
ORDER BY j.total_net_profit DESC
LIMIT 50;
