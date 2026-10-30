
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), AggregatedSales AS (
    SELECT 
        SalesCTE.ws_item_sk,
        SalesCTE.total_sales,
        COALESCE(StoreSales.total_store_sales, 0) AS total_store_sales,
        (SalesCTE.total_sales + COALESCE(StoreSales.total_store_sales, 0)) AS combined_sales
    FROM 
        SalesCTE
    LEFT JOIN 
        StoreSales ON SalesCTE.ws_item_sk = StoreSales.ss_item_sk
    WHERE 
        SalesCTE.sales_rank <= 10
), CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
)
SELECT 
    ag.ws_item_sk,
    ag.total_sales,
    ag.total_store_sales,
    ag.combined_sales,
    CASE 
        WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
        ELSE cd.cd_marital_status
    END AS marital_status,
    STRING_AGG(CONCAT(cd.cd_gender, ' (Est. Purchases: ', cd.cd_purchase_estimate, ')'), ', ') AS demographic_info
FROM 
    AggregatedSales ag
LEFT JOIN 
    (
        SELECT 
            c_current_cdemo_sk, 
            c_customer_sk
        FROM 
            customer
    ) AS cust ON ag.ws_item_sk = cust.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON cust.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ag.ws_item_sk, ag.total_sales, ag.total_store_sales, ag.combined_sales, cd.cd_marital_status
ORDER BY 
    ag.combined_sales DESC
LIMIT 20;
