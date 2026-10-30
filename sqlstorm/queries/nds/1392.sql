
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        cr.sr_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(cd.cd_education_status, 'Unknown') AS education_status
    FROM
        CustomerReturns cr
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cr.sr_customer_sk
    WHERE
        cr.total_return_amt > 0
)
SELECT
    tc.sr_customer_sk,
    tc.gender,
    tc.marital_status,
    tc.education_status,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_spent,
    AVG(rs.ws_sales_price) AS avg_item_price,
    (CASE 
        WHEN COUNT(DISTINCT rs.ws_order_number) > 5 THEN 'Frequent' 
        ELSE 'Occasional' 
    END) AS customer_freq_category
FROM
    TopCustomers tc
LEFT JOIN RankedSales rs ON tc.sr_customer_sk = rs.ws_order_number
GROUP BY
    tc.sr_customer_sk, 
    tc.gender, 
    tc.marital_status, 
    tc.education_status;
