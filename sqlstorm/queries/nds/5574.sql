
WITH SalesStats AS (
    SELECT 
        s.ss_store_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_profit) AS total_profit,
        AVG(s.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.ss_store_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk, 
        COUNT(hd.hd_demo_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    s.ss_store_sk,
    s.total_quantity,
    s.total_profit,
    s.avg_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    ir.customer_count AS total_customers_in_income_band
FROM 
    SalesStats s
JOIN 
    CustomerDemographics cd ON cd.c_customer_sk IN (SELECT DISTINCT ss_customer_sk FROM store_sales WHERE ss_store_sk = s.ss_store_sk)
LEFT JOIN 
    IncomeRanges ir ON ir.ib_income_band_sk = (SELECT DISTINCT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_demo_sk IN (SELECT DISTINCT c.c_current_hdemo_sk FROM customer c WHERE c.c_current_addr_sk IN (SELECT DISTINCT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_state = 'CA')))
WHERE 
    s.total_profit > 10000
ORDER BY 
    s.ss_store_sk;
