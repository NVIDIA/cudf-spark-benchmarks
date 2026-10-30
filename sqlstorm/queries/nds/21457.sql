
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cd_purchase_estimate DESC) AS demo_rank
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
TopDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cd.cd_demo_sk) AS customer_count
    FROM 
        CustomerDemographics cd
    WHERE 
        cd.cd_purchase_estimate > 200
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    td.cd_gender,
    td.cd_marital_status,
    COALESCE(td.customer_count, 0) AS customer_count
FROM 
    TopItems ti
LEFT JOIN 
    TopDemographics td ON (td.cd_gender IS NOT NULL AND LENGTH(td.cd_marital_status) > 0)
WHERE 
    ti.total_sales > (
        SELECT AVG(total_sales) 
        FROM TopItems
    ) 
    OR (
        (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk = ti.ws_item_sk) 
        > (SELECT COUNT(*) FROM store_returns WHERE sr_item_sk = ti.ws_item_sk)
    )
ORDER BY 
    ti.total_sales DESC, 
    td.customer_count DESC
LIMIT 50;
