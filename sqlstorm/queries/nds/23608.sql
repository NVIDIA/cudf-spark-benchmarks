
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_net_paid > 0
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS TotalQuantity,
        COUNT(DISTINCT rs.ws_order_number) AS OrderCount
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 3
    GROUP BY 
        rs.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_dep_count AS STRING)
        END AS DepCountDescription
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(TI.TotalQuantity) AS TotalSold,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM 
        TopItems TI
    JOIN 
        web_sales ws ON TI.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerDemographics cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    sbd.cd_gender,
    sbd.cd_marital_status,
    COALESCE(sbd.TotalSold, 0) AS TotalSold,
    COALESCE(sbd.AvgPurchaseEstimate, 0) AS AvgPurchaseEstimate,
    CASE
        WHEN sbd.TotalSold > 100 THEN 'High Volume'
        WHEN sbd.TotalSold BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS VolumeCategory
FROM 
    SalesByDemographics sbd
FULL OUTER JOIN 
    (SELECT DISTINCT cd_gender, cd_marital_status FROM CustomerDemographics) cd
    ON sbd.cd_gender = cd.cd_gender AND sbd.cd_marital_status = cd.cd_marital_status
ORDER BY 
    sbd.cd_gender, sbd.cd_marital_status;
