
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnsSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_net_loss) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
FinalSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.cd_credit_rating,
        cs.ca_city,
        cs.ca_state,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(rs.total_returns, 0) AS total_returns
    FROM CustomerSummary cs
    LEFT JOIN SalesSummary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN ReturnsSummary rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    c.total_sales,
    c.total_orders,
    c.total_returns,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM FinalSummary c
WHERE c.total_sales IS NOT NULL OR c.total_orders > 0
ORDER BY c.total_sales DESC, c.total_orders DESC
LIMIT 100;
