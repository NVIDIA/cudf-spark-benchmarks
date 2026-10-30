
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price ASC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
        AND ws_sales_price > 0
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE profit_rank <= 10)
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c_current_cdemo_sk, cd_gender, cd_marital_status
)
SELECT 
    c.c_customer_id,
    SUM(ss.total_net_profit) AS net_profit_sum,
    AVG(cd.avg_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
    SUM(COALESCE(NULLIF(cs.cs_ext_sales_price, 0), NULL)) AS adjusted_catalog_sales
FROM 
    customer c
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.c_current_cdemo_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1995
    AND (cd_gender = 'F' OR cd_marital_status = 'M')
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ss.total_net_profit) > 5000 
    OR AVG(cd.avg_purchase_estimate) > 1000
ORDER BY 
    net_profit_sum DESC,
    avg_purchase_estimate DESC
LIMIT 50;
