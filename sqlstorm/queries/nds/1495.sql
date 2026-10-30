
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        wr_returning_customer_sk
    FROM RankedReturns
    WHERE rank <= 10
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        hrc.wr_returning_customer_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(sd.avg_sales_price, 0) AS avg_sales_price,
        rr.total_return_quantity
    FROM HighReturnCustomers hrc
    LEFT JOIN SalesData sd ON hrc.wr_returning_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN RankedReturns rr ON hrc.wr_returning_customer_sk = rr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
    cb.total_sales,
    cb.order_count,
    cb.total_return_quantity,
    CASE 
        WHEN cb.total_sales > 0 THEN (cb.total_return_quantity * 100.0 / cb.total_sales)
        ELSE 0
    END AS return_percentage
FROM CombinedData cb
JOIN customer c ON cb.wr_returning_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
  AND cb.total_return_quantity > 0
ORDER BY return_percentage DESC, cb.total_sales DESC;
