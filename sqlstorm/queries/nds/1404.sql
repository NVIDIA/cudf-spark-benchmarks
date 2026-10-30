
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
SalesWithReturns AS (
    SELECT
        s.ws_bill_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cc.cc_name, 'Unknown') AS call_center_name,
        s.total_quantity_sold,
        s.total_sales_amount,
        COALESCE(cr.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(cr.total_return_amount, 0) AS returned_amount
    FROM
        SalesData s
    LEFT JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN call_center cc ON cd.cd_demo_sk = cc.cc_call_center_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
),
RankedSales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_sales_amount DESC) AS sales_rank
    FROM
        SalesWithReturns
)
SELECT
    s.*,
    CASE 
        WHEN returned_quantity > total_quantity_sold THEN 'High Return Rate'
        WHEN returned_quantity > 0 THEN 'Some Returns'
        ELSE 'No Returns'
    END AS return_status
FROM
    RankedSales s
WHERE
    gender = 'F' AND sales_rank <= 10
ORDER BY
    total_sales_amount DESC;

