
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) + COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales
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
SalesRanked AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
),
TopCustomers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_web_sales,
        s.total_catalog_sales,
        s.total_store_sales,
        s.total_sales
    FROM 
        SalesRanked s
    WHERE 
        s.sales_rank <= 10
),
CustomerDetails AS (
    SELECT 
        tc.*,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        TopCustomers tc
    LEFT JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.total_web_sales,
    cd.total_catalog_sales,
    cd.total_store_sales,
    cd.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(hd.hd_dep_count, 0) AS dependent_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    household_demographics hd ON cd.c_customer_sk = hd.hd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    (hd.hd_buy_potential IS NOT NULL OR hd.hd_buy_potential = 'High')
ORDER BY 
    cd.total_sales DESC
LIMIT 15;
