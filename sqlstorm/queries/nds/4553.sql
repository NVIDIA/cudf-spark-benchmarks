
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ce.total_sales
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN RankedSales ce ON c.c_customer_sk = ce.ws_bill_customer_sk
    WHERE
        cd.cd_gender IS NOT NULL AND
        cd.cd_marital_status = 'M'
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    COALESCE(cd.total_sales, 0) AS total_sales,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cd.c_customer_sk) AS store_orders,
    (SELECT SUM(sr_return_amt) FROM store_returns sr WHERE sr.sr_customer_sk = cd.c_customer_sk) AS total_store_returns,
    (SELECT SUM(wr_return_amt) FROM web_returns wr WHERE wr.wr_returning_customer_sk = cd.c_customer_sk) AS total_web_returns
FROM 
    CustomerDetails cd
WHERE 
    cd.total_sales > 50000
ORDER BY 
    cd.total_sales DESC
LIMIT 10;
