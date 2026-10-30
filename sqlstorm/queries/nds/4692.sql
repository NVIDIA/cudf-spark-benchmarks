
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY d.d_year ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeSales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
AverageSales AS (
    SELECT 
        d.d_year,
        AVG(CumulativeSales) AS AvgCumulativeSales
    FROM 
        SalesData
    JOIN 
        date_dim d ON SalesData.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
HighestReturnReasons AS (
    SELECT 
        r.r_reason_desc,
        COUNT(cr.cr_returned_date_sk) AS ReturnCount
    FROM 
        catalog_returns cr
    JOIN 
        reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
    HAVING 
        COUNT(cr.cr_returned_date_sk) > 100
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    asd.AvgCumulativeSales,
    hrr.r_reason_desc,
    hrr.ReturnCount
FROM 
    RankedCustomers rc
LEFT JOIN 
    AverageSales asd ON 1=1
LEFT JOIN 
    HighestReturnReasons hrr ON rc.cd_purchase_estimate > asd.AvgCumulativeSales
WHERE 
    rc.PurchaseRank <= 10
ORDER BY 
    rc.cd_purchase_estimate DESC, hrr.ReturnCount DESC;
