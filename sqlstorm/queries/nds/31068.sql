
WITH  SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
TopSales AS (
    SELECT
        s.ws_bill_customer_sk,
        s.total_sales,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_credit_rating,
        c.income_band,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) as row_num
    FROM SalesData s
    JOIN CustomerInfo c ON s.ws_bill_customer_sk = c.c_customer_sk
    WHERE s.sales_rank <= 10
),
StoreDetails AS (
    SELECT
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    GROUP BY ss_store_sk
)
SELECT
    ts.c_first_name,
    ts.c_last_name,
    ts.cd_gender,
    ts.cd_marital_status,
    ts.cd_credit_rating,
    ts.income_band,
    ts.total_sales,
    sd.total_transactions
FROM TopSales ts
LEFT JOIN StoreDetails sd ON sd.ss_store_sk = (SELECT s.s_store_sk 
                                               FROM store s 
                                               WHERE s.s_country = 'USA' 
                                               ORDER BY s.s_number_employees DESC
                                               LIMIT 1)
WHERE ts.income_band IS NOT NULL
AND (ts.cd_gender = 'F' OR ts.cd_marital_status = 'S')
ORDER BY ts.total_sales DESC;
