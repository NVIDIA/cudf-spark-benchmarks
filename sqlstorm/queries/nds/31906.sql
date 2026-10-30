
WITH  SalesOverview AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS recent_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependent_count
    FROM 
        customer_demographics 
    LEFT JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_paid) AS total_store_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
CombinedSales AS (
    SELECT 
        so.ws_item_sk,
        so.total_quantity + COALESCE(ss.total_store_quantity, 0) AS combined_quantity,
        so.total_sales + COALESCE(ss.total_store_sales, 0) AS combined_sales
    FROM 
        SalesOverview so
    LEFT JOIN 
        StoreSales ss ON so.ws_item_sk = ss.ss_item_sk
),
FinalSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.combined_quantity) AS total_quantity,
        SUM(cs.combined_sales) AS total_sales,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_desc
    FROM 
        CombinedSales cs
    JOIN 
        CustomerDemographics cd ON cs.ws_item_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    fs.gender_desc,
    fs.cd_marital_status,
    fs.total_quantity,
    fs.total_sales,
    fs.total_sales / NULLIF(fs.total_quantity, 0) AS avg_sales_per_quantity
FROM 
    FinalSales fs
WHERE 
    fs.total_sales > 1000
    AND fs.total_quantity IS NOT NULL
ORDER BY 
    fs.total_sales DESC
LIMIT 10;
