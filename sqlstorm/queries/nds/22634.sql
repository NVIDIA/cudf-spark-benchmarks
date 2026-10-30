
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Unknown'), 'Not Rated') AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_per_gender
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
returns_info AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count,
        MAX(wr.wr_returned_date_sk) AS last_return
    FROM
        web_returns wr
    GROUP BY
        wr.wr_returning_customer_sk
),
aggregated_info AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.return_count, 0) AS return_count,
        CASE
            WHEN si.total_sales - COALESCE(ri.total_returns, 0) > 1000 THEN 'High Value'
            WHEN si.total_sales - COALESCE(ri.total_returns, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment,
        CASE 
            WHEN last_purchase > last_return THEN 'Recently Purchased'
            ELSE 'Potentially Churned'
        END AS purchase_trend
    FROM
        customer_info ci
    LEFT JOIN
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN
        returns_info ri ON ci.c_customer_sk = ri.wr_returning_customer_sk
)
SELECT
    ai.c_customer_sk,
    ai.c_first_name,
    ai.c_last_name,
    ai.c_email_address,
    ai.cd_gender,
    ai.cd_marital_status,
    ai.total_sales,
    ai.order_count,
    ai.total_returns,
    ai.return_count,
    ai.customer_value_segment,
    ai.purchase_trend
FROM
    aggregated_info ai
WHERE
    ai.cd_gender = 'F'
    AND ai.total_sales IS NOT NULL
ORDER BY
    ai.order_count DESC,
    ai.total_sales DESC
LIMIT 100;
