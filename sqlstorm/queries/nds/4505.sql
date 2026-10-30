
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_return_quantity) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
final_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.hd_income_band_sk,
        ss.total_sales,
        ss.order_count,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amt, 0)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY ci.hd_income_band_sk ORDER BY COALESCE(ss.total_sales, 0) DESC) AS income_band_rank
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN return_summary rs ON ci.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    c_customer_sk AS customer_sk,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    total_return_amt,
    total_returns,
    net_sales,
    income_band_rank
FROM final_summary
WHERE net_sales > 0
ORDER BY income_band_rank, total_sales DESC
LIMIT 10;
