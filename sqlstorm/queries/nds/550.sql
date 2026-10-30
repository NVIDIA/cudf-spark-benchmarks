
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MIN(ws.ws_sales_price) AS min_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
return_data AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned_amount,
        COUNT(wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_id,
        sd.total_sales,
        sd.total_orders,
        rd.total_returned_amount,
        rd.total_returns,
        CASE 
            WHEN sd.total_sales IS NULL THEN 0 
            ELSE (COALESCE(rd.total_returned_amount, 0) / sd.total_sales) * 100 
        END AS return_percentage,
        ci.cd_gender
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN return_data rd ON ci.c_customer_sk = rd.wr_returning_customer_sk
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_orders,
    f.total_returned_amount,
    f.total_returns,
    f.return_percentage,
    f.cd_gender
FROM final_report f
WHERE f.return_percentage >= 10 OR f.total_orders > 5
ORDER BY f.return_percentage DESC, f.total_sales DESC
LIMIT 50;
