WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_item_sk) AS total_items_bought
    FROM 
        customer AS c
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000  
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer_demographics AS cd
    JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Aggregated AS (
    SELECT 
        cs.c_customer_id,
        ROUND(cs.total_sales, 2) AS total_sales,
        cs.total_transactions,
        cs.avg_sales_price,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.ib_income_band_sk
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        Demographics AS dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
)
SELECT 
    ag.cd_gender,
    ag.cd_marital_status,
    ag.ib_income_band_sk,
    COUNT(ag.c_customer_id) AS customer_count,
    SUM(ag.total_sales) AS total_sales,
    AVG(ag.avg_sales_price) AS avg_sales_price,
    AVG(ag.total_transactions) AS avg_transactions
FROM 
    Aggregated AS ag
GROUP BY 
    ag.cd_gender, ag.cd_marital_status, ag.ib_income_band_sk
ORDER BY 
    customer_count DESC;