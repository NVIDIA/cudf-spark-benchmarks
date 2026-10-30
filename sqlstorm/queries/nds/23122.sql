
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales ws
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturns,
        COUNT(DISTINCT wr.wr_order_number) AS ReturnCount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    cd.cd_gender,
    sd.ws_item_sk,
    SUM(sd.ws_quantity) AS TotalQuantitySold,
    AVG(sd.ws_sales_price) AS AveragePrice,
    COALESCE(rd.TotalReturns, 0) AS TotalReturns,
    CASE 
        WHEN COALESCE(rd.TotalReturns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS ReturnStatus,
    CASE 
        WHEN rc.PurchaseRank = 1 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS BuyerType
FROM 
    RankedCustomers rc
JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
JOIN 
    customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    rc.c_first_name, 
    rc.c_last_name, 
    cd.cd_gender, 
    sd.ws_item_sk, 
    rc.PurchaseRank, 
    rd.TotalReturns
HAVING 
    SUM(sd.ws_quantity) > 100
ORDER BY 
    TotalQuantitySold DESC, 
    AveragePrice ASC
LIMIT 50;
