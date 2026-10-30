
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_items,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS total_return_transactions
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_purchased_items,
        SUM(ws_sales_price) AS total_sales_amount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), CustomerMetrics AS (
    SELECT 
        COALESCE(cr.wr_returning_customer_sk, cs.ws_bill_customer_sk) AS customer_id,
        COALESCE(cr.total_returned_items, 0) AS total_returned_items,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(cs.total_purchased_items, 0) AS total_purchased_items,
        COALESCE(cs.total_sales_amount, 0) AS total_sales_amount
    FROM CustomerReturns cr
    FULL OUTER JOIN CustomerSales cs ON cr.wr_returning_customer_sk = cs.ws_bill_customer_sk
), Demographics AS (
    SELECT 
        c.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        cm.total_returned_items,
        cm.total_returned_amount,
        cm.total_purchased_items,
        cm.total_sales_amount
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN CustomerMetrics cm ON c.c_customer_sk = cm.customer_id
)
SELECT 
    ROUND(AVG(total_sales_amount) / NULLIF(AVG(total_returned_amount), 0), 2) AS avg_sales_to_return_ratio,
    COUNT(DISTINCT c_customer_id) AS num_customers,
    COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
    COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
    COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count,
    COUNT(CASE WHEN cd_education_status = 'Postgraduate' THEN 1 END) AS postgraduate_count
FROM Demographics
WHERE total_purchased_items > 0
GROUP BY cd_gender
HAVING AVG(total_returned_items) < 5;
