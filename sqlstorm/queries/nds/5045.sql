
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk)
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_bill_customer_sk
), CustomerStats AS (
    SELECT 
        cd_demo_sk,
        SUM(total_sales) AS total_sales_by_customer,
        COUNT(*) AS sales_transaction_count
    FROM 
        SalesData
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender = 'F' AND cd_marital_status = 'M'
    GROUP BY 
        cd_demo_sk
), IncomeStats AS (
    SELECT 
        ib_income_band_sk,
        AVG(total_sales_by_customer) AS avg_sales_per_income_band,
        SUM(sales_transaction_count) AS total_transactions
    FROM 
        CustomerStats
    JOIN 
        household_demographics ON hd_demo_sk = cd_demo_sk
    JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY 
        ib_income_band_sk
)
SELECT 
    ib_income_band_sk,
    avg_sales_per_income_band,
    total_transactions
FROM 
    IncomeStats
ORDER BY 
    avg_sales_per_income_band DESC
LIMIT 10;
