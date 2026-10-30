
WITH sales_summary AS (
    SELECT 
        CASE 
            WHEN ws_bill_customer_sk IS NULL THEN 'Store'
            ELSE 'Web'
        END AS sales_channel,
        COALESCE(SUM(ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 
        CASE 
            WHEN ws_bill_customer_sk IS NULL THEN 'Store'
            ELSE 'Web'
        END
), income_summary AS (
    SELECT 
        CASE 
            WHEN hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band ', hd_income_band_sk)
        END AS income_band,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        CASE 
            WHEN hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band ', hd_income_band_sk)
        END
), combined_summary AS (
    SELECT 
        ss.sales_channel,
        ss.total_profit,
        ss.order_count,
        ss.unique_customers,
        COALESCE(income_summary.income_band, 'Total') AS income_band,
        AVG(income_summary.avg_purchase_estimate) AS avg_purchase_estimate
    FROM sales_summary ss
    LEFT JOIN income_summary ON ss.sales_channel = 'Web' AND ss.total_profit > 0
    GROUP BY 
        ss.sales_channel, 
        ss.total_profit, 
        ss.order_count, 
        ss.unique_customers, 
        income_summary.income_band
)
SELECT 
    sales_channel,
    SUM(total_profit) AS total_profit,
    SUM(order_count) AS total_orders,
    SUM(unique_customers) AS total_unique_customers,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate
FROM combined_summary
GROUP BY sales_channel
HAVING SUM(total_profit) > 0
ORDER BY total_profit DESC;
