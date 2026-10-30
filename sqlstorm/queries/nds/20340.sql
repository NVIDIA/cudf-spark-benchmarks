
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        AVG(sr_return_amt) AS AvgReturnAmt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
ReturnStatistics AS (
    SELECT 
        i.i_item_sk,
        COALESCE(ar.TotalReturns, 0) AS TotalReturns,
        COALESCE(ar.AvgReturnAmt, 0) AS AvgReturnAmt,
        CASE WHEN COALESCE(ar.TotalReturns, 0) = 0 THEN 'No Returns' ELSE 'Returns Exist' END AS ReturnStatus
    FROM 
        item i 
    LEFT JOIN  
        AggregatedReturns ar ON i.i_item_sk = ar.sr_item_sk
),
CustomerGenderStats AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT
    r.Item,
    r.TotalReturns,
    r.AvgReturnAmt,
    cgs.cd_gender AS CustomerGender,
    cgs.CustomerCount,
    cgs.AvgPurchaseEstimate
FROM 
    (SELECT 
         i.i_item_id AS Item,
         r.TotalReturns,
         r.AvgReturnAmt
     FROM 
         ReturnStatistics r 
     JOIN 
         item i ON r.i_item_sk = i.i_item_sk
     WHERE 
         r.TotalReturns > 5) r
FULL OUTER JOIN 
    CustomerGenderStats cgs ON r.TotalReturns = cgs.CustomerCount
WHERE 
    (r.TotalReturns IS NOT NULL OR cgs.CustomerCount IS NOT NULL)
ORDER BY 
    r.TotalReturns DESC NULLS LAST, 
    cgs.CustomerCount DESC NULLS LAST;
