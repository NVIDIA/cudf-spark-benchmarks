
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), recent_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), store_sales_stats AS (
    SELECT 
        ss_store_sk,
        AVG(ss_net_profit) AS avg_net_profit, 
        MAX(ss_net_paid) AS max_net_paid,
        COUNT(DISTINCT ss_item_sk) AS item_count
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), return_analysis AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), final_metrics AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name, 
        rs.total_sales, 
        rs.order_count,
        COALESCE(ra.total_returns, 0) AS total_returns,
        COALESCE(ra.total_return_amt, 0.00) AS total_return_amt,
        cs.avg_net_profit,
        cs.max_net_paid,
        cs.item_count
    FROM 
        customer_data cd
    LEFT JOIN 
        recent_sales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        return_analysis ra ON cd.c_customer_sk = ra.sr_customer_sk
    LEFT JOIN 
        store_sales_stats cs ON cd.c_customer_sk = cs.ss_store_sk
    WHERE 
        cd.rn = 1 AND 
        (rs.total_sales IS NOT NULL OR ra.total_returns IS NOT NULL)
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROUND((total_sales - total_return_amt) / NULLIF(total_sales, 0), 2) AS net_sales_ratio,
    LEAST(item_count + COALESCE(total_returns, 0), 100) AS adjusted_item_count
FROM 
    final_metrics
ORDER BY 
    total_sales DESC NULLS LAST;
