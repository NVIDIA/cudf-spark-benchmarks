
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
        LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
SalesMetrics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedMetrics AS (
    SELECT
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.total_web_returns,
        cm.total_store_returns,
        COALESCE(sm.total_net_profit, 0) AS total_net_profit,
        COALESCE(sm.total_orders, 0) AS total_orders,
        CASE 
            WHEN cm.total_web_returns > 0 THEN 'High Return Rate'
            WHEN cm.total_store_returns > 0 THEN 'Some Store Returns'
            ELSE 'Low Return Rate'
        END AS return_category
    FROM 
        CustomerMetrics cm
        LEFT JOIN SalesMetrics sm ON cm.c_customer_sk = sm.ws_bill_customer_sk
)
SELECT 
    return_category,
    COUNT(*) AS customer_count,
    AVG(total_net_profit) AS avg_net_profit,
    SUM(total_orders) AS overall_orders,
    SUM(total_web_returns) AS total_web_returns,
    SUM(total_store_returns) AS total_store_returns
FROM 
    CombinedMetrics
GROUP BY 
    return_category
ORDER BY 
    customer_count DESC;
