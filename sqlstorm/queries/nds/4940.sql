
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
CustomerInfo AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.web_sales_count,
        cs.catalog_sales_count,
        cs.store_sales_count,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        CustomerSales cs
    JOIN 
        Demographics dm ON cs.c_customer_sk = dm.cd_demo_sk
    LEFT JOIN 
        income_band ib ON dm.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cs.profit_rank <= 10 AND 
        (ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL)
),
FinalReport AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.total_net_profit,
        c.web_sales_count,
        c.catalog_sales_count,
        c.store_sales_count,
        CONCAT(c.cd_gender, '-', c.cd_marital_status) AS demographic_profile,
        CASE 
            WHEN c.total_net_profit > 10000 THEN 'High Value'
            WHEN c.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        CustomerInfo c
)
SELECT 
    fr.*,
    (SELECT AVG(total_net_profit) FROM FinalReport) AS avg_net_profit,
    (SELECT COUNT(*) FROM FinalReport WHERE value_category = 'High Value') AS high_value_customers
FROM 
    FinalReport fr
ORDER BY 
    fr.total_net_profit DESC;
