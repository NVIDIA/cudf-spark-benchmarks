
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), 
IncomeRanges AS (
    SELECT 
        hd_income_band_sk,
        CASE 
            WHEN hd_dep_count > 2 THEN 'High-Income'
            WHEN hd_dep_count BETWEEN 1 AND 2 THEN 'Middle-Income'
            ELSE 'Low-Income'
        END AS income_category
    FROM 
        household_demographics
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ir.income_category
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        IncomeRanges ir ON cd.cd_demo_sk = ir.hd_income_band_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ir.income_category
), 
AggregateSales AS (
    SELECT 
        cs.income_category,
        AVG(cs.customer_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.c_customer_id) AS unique_customers
    FROM 
        CustomerSales cs
    GROUP BY 
        cs.income_category
)
SELECT 
    ar.income_category,
    ar.avg_net_profit,
    ar.unique_customers,
    sa.total_net_sales,
    sa.total_transactions
FROM 
    AggregateSales ar
JOIN 
    SalesCTE sa ON sa.sales_rank = 1
ORDER BY 
    ar.avg_net_profit DESC, sa.total_net_sales DESC;
