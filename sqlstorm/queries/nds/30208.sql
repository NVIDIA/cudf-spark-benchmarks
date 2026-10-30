
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_ext_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (
        SELECT MIN(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    ) AND (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(cr.total_returned, 0)) AS total_returns,
        SUM(COALESCE(cr.total_return_amt, 0)) AS return_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_month_seq
),
TopSales AS (
    SELECT 
        RANK() OVER (ORDER BY monthly_sales DESC) AS sales_rank,
        ms.d_month_seq,
        ms.monthly_sales,
        ms.orders_count
    FROM MonthlySales ms
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cr.sr_customer_sk) AS return_customers,
    SUM(cd.total_returns) AS total_returns,
    SUM(cd.return_amount) AS return_amount,
    COALESCE(ts.monthly_sales, 0) AS top_monthly_sales
FROM CustomerDemographics cd
LEFT JOIN TopSales ts ON ts.sales_rank = 1
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
GROUP BY cd.cd_gender, cd.cd_marital_status, ts.monthly_sales
ORDER BY return_customers DESC, return_amount DESC;
