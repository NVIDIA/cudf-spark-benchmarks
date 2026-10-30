
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS TotalQuantity,
        COUNT(DISTINCT rs.ws_order_number) AS UniqueOrders
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 5
    GROUP BY 
        rs.ws_item_sk
),
HighIncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        SUM(cd.cd_purchase_estimate) AS TotalPurchaseEstimate
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    si.i_item_id,
    si.i_item_desc,
    ti.TotalQuantity,
    hi.TotalPurchaseEstimate,
    COALESCE(hi.TotalPurchaseEstimate / NULLIF(ti.TotalQuantity, 0), 0) AS PurchasePerItem
FROM 
    item si
LEFT JOIN 
    TopSellingItems ti ON si.i_item_sk = ti.ws_item_sk
LEFT JOIN 
    HighIncomeDemographics hi ON ti.ws_item_sk = hi.hd_demo_sk
WHERE 
    (hi.TotalPurchaseEstimate IS NOT NULL OR ti.TotalQuantity > 0)
ORDER BY 
    PurchasePerItem DESC
LIMIT 10;
