WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeGroups AS (
    SELECT 
        h.hd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown' 
            WHEN ib.ib_upper_bound IS NULL THEN 'High Income'
            ELSE CONCAT(CAST(ib.ib_lower_bound AS STRING), ' - ', CAST(ib.ib_upper_bound AS STRING))
        END AS income_band,
        AVG(cs.total_sales) AS avg_sales
    FROM 
        household_demographics h
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN CustomerSales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        h.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
TopIncomeGroups AS (
    SELECT 
        income_band,
        RANK() OVER (ORDER BY AVG(avg_sales) DESC) AS income_rank,
        AVG(avg_sales) AS avg_sales
    FROM 
        IncomeGroups
    GROUP BY 
        income_band
)
SELECT 
    tig.income_band,
    tig.avg_sales,
    CASE WHEN tig.income_rank <= 3 THEN 'Top Income Group' ELSE 'Other' END AS category,
    COALESCE(CAST(cast('2002-10-01' as date) - INTERVAL '1' YEAR AS STRING), 'Date not available') AS date_fetched,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year >= 1990) AS birth_year_1990_or_later
FROM 
    TopIncomeGroups tig
WHERE 
    tig.avg_sales > (SELECT AVG(avg_sales) FROM TopIncomeGroups) 
ORDER BY 
    tig.avg_sales DESC;