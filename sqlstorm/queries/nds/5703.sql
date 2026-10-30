WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_sales_price) AS average_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600 
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
SalesStatistics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(transaction_count) AS total_transactions
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    avg_sales,
    total_transactions,
    CASE 
        WHEN avg_sales > 1000 THEN 'High Value'
        WHEN avg_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesStatistics
ORDER BY 
    customer_value_category DESC, avg_sales DESC;