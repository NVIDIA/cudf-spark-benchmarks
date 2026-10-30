
WITH DailySales AS (
    SELECT 
        d.d_date AS SaleDate,
        SUM(ws.ws_quantity) AS TotalQuantity,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        SUM(ws.ws_net_profit) AS TotalProfit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
GenderDemographics AS (
    SELECT 
        cd.cd_gender, 
        SUM(cd.cd_dep_count) AS TotalDependents,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS TotalSold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        TotalSold DESC
    LIMIT 10
)
SELECT 
    ds.SaleDate,
    ds.TotalQuantity,
    ds.TotalSales,
    ds.TotalProfit,
    gd.cd_gender,
    gd.TotalDependents,
    gd.AvgPurchaseEstimate,
    ti.i_item_id,
    ti.i_item_desc,
    ti.TotalSold
FROM 
    DailySales ds
JOIN 
    GenderDemographics gd ON gd.TotalDependents > 10
CROSS JOIN 
    TopItems ti
WHERE 
    ds.SaleDate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    ds.SaleDate, ds.TotalSales DESC;
