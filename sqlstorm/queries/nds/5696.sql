
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('Bachelor', 'Master')
),
AverageSales AS (
    SELECT
        rs.ws_item_sk,
        AVG(rs.ws_sales_price) AS AverageSalesPrice,
        SUM(rs.ws_quantity) AS TotalQuantitySold
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    asales.AverageSalesPrice,
    asales.TotalQuantitySold
FROM 
    AverageSales asales
JOIN 
    item i ON asales.ws_item_sk = i.i_item_sk
ORDER BY 
    asales.AverageSalesPrice DESC
LIMIT 10;
