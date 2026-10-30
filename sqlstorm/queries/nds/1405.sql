
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 60
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_income_band_sk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
SalesRanked AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales, 
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 1 AND 60
    GROUP BY ss.ss_store_sk
),
RankedStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.store_sales,
        RANK() OVER (ORDER BY ss.store_sales DESC) AS store_rank
    FROM store s
    JOIN StoreSales ss ON s.s_store_sk = ss.ss_store_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(RS.store_sales, 0) AS store_sales,
    COALESCE(cs.total_sales, 0) AS customer_sales,
    S.sales_rank,
    RS.store_rank
FROM CustomerSales cs
JOIN SalesRanked S ON cs.c_customer_sk = S.c_customer_sk
LEFT JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN RankedStores RS ON S.sales_rank = RS.store_rank
WHERE (cd.cd_gender IS NULL OR cd.cd_gender = 'M') 
  AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY S.sales_rank, RS.store_rank;
