
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS average_transaction_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
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
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        total_sales,
        total_transactions,
        average_transaction_value,
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    customer_id,
    total_sales,
    total_transactions,
    average_transaction_value,
    cd_gender,
    cd_marital_status,
    ib_income_band_sk,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    ib_income_band_sk, sales_rank;
