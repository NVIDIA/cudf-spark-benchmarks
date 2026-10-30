
WITH  customer_cte AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, 
           COALESCE(cd.cd_gender, 'U') AS gender, 
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE c.c_first_name IS NOT NULL
      AND c.c_last_name IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
final_summary AS (
    SELECT 
        cte.c_customer_sk,
        cte.c_first_name,
        cte.c_last_name,
        cte.gender,
        cte.buy_potential,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.avg_net_profit, 0) AS avg_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value
    FROM customer_cte cte
    LEFT JOIN sales_summary ss ON cte.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN return_summary rs ON cte.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.gender,
    f.buy_potential,
    f.total_orders,
    f.total_sales,
    f.avg_net_profit,
    f.total_returns,
    f.total_return_value,
    CASE WHEN f.total_sales > 1000 THEN 'High Value' 
         WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
         ELSE 'Low Value' END AS customer_value_category
FROM final_summary f
WHERE (f.total_orders > 0 AND f.total_sales IS NOT NULL) 
   OR (f.total_returns > 0 AND f.total_return_value IS NOT NULL)
ORDER BY f.total_sales DESC, f.c_last_name ASC
LIMIT 100;
