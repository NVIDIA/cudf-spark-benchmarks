
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2454845 AND 2454910
    GROUP BY ws_bill_customer_sk
), demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    INNER JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender
), final_summary AS (
    SELECT 
        ds.ws_bill_customer_sk,
        ds.total_sales,
        ds.total_profit,
        ds.total_orders,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate
    FROM sales_summary ds
    JOIN demographic_summary d ON ds.ws_bill_customer_sk = d.cd_demo_sk
)
SELECT 
    fs.ws_bill_customer_sk,
    fs.total_sales,
    fs.total_profit,
    fs.total_orders,
    fs.cd_gender,
    fs.customer_count,
    fs.avg_purchase_estimate
FROM final_summary fs
WHERE fs.total_orders > 5 AND fs.total_profit > 1000
ORDER BY fs.total_sales DESC
LIMIT 100;
