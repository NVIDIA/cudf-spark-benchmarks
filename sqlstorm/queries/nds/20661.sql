
WITH RankedStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        DENSE_RANK() OVER (ORDER BY s_number_employees DESC) AS employee_rank
    FROM store
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS num_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
EligibleCustomers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cr.num_returns, 0) AS returns,
        COALESCE(cr.total_returned_amt, 0) AS return_amt,
        CASE 
            WHEN cr.num_returns > 5 THEN 'High'
            WHEN cr.num_returns BETWEEN 1 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    es.c_customer_sk,
    es.cd_gender,
    es.return_category,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_web_sales,
    SUM(CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_sales_price ELSE 0 END) AS high_value_sales,
    SUM(CASE WHEN ws.ws_sales_price IS NULL THEN 1 ELSE 0 END) AS null_sales_count
FROM EligibleCustomers es 
LEFT JOIN web_sales ws ON es.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY es.c_customer_sk, es.cd_gender, es.return_category
HAVING SUM(ws.ws_sales_price) > (
    SELECT AVG(total_web_sales) 
    FROM (
        SELECT SUM(ws_sales_price) AS total_web_sales 
        FROM web_sales 
        GROUP BY ws_bill_customer_sk
    ) AS avg_sales
)
ORDER BY total_web_sales DESC
LIMIT 10
