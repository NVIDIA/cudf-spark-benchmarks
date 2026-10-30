
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amt,
        SUM(sr_return_quantity) AS total_returned_qty
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
CombinedStats AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.purchase_category,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_amt, 0) AS total_returned_amt,
        ss.total_sales,
        ss.order_count,
        cm.gender_rank
    FROM 
        CustomerMetrics cm
    LEFT JOIN 
        ReturnStats rs ON cm.c_customer_sk = rs.sr_customer_sk
    LEFT JOIN 
        SalesStats ss ON cm.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN purchase_category = 'High' AND total_returns > 0 THEN 'Potentially Price Sensitive'
        ELSE 'Normal'
    END AS customer_status,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS ranking,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN total_sales > 1000 THEN 'VIP Customer'
                ELSE 'Regular Customer'
            END
    END AS customer_type
FROM 
    CombinedStats
WHERE 
    (gender_rank = 1 OR total_returns > 5)
    AND (total_sales IS NOT NULL OR total_returned_amt > 500)
ORDER BY 
    customer_type DESC, full_name
LIMIT 50 OFFSET 10;
