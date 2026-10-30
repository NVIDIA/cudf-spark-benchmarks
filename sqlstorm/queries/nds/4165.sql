WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_store_return_value
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_value
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451818 AND 2452156  
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
    COALESCE(cd.cd_gender, 'N/A') AS customer_gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    COALESCE(cd.cd_education_status, 'N/A') AS education_status,
    COALESCE(cr.total_store_returns, 0) AS store_return_count,
    COALESCE(cr.total_store_return_value, 0) AS store_return_value,
    COALESCE(wr.total_web_returns, 0) AS web_return_count,
    COALESCE(wr.total_web_return_value, 0) AS web_return_value,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    CASE 
        WHEN sd.total_sales > 5000 THEN 'VIP Customer'
        WHEN sd.total_sales BETWEEN 1000 AND 5000 THEN 'Regular Customer'
        ELSE 'Occasional Customer'
    END AS customer_segment
FROM
    customer c
LEFT JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN
    WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN
    SalesData sd ON c.c_customer_sk = sd.customer_sk
ORDER BY
    total_sales DESC,
    store_return_value DESC
LIMIT 100;