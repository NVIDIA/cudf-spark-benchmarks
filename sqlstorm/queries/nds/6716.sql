WITH MonthlySales AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalSales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WarehouseInventory AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalInventory
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ms.SalesYear,
    ms.SalesMonth,
    ms.TotalSales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.CustomerCount,
    wi.TotalInventory
FROM 
    MonthlySales ms
JOIN 
    CustomerDemographics cd ON 1=1  
JOIN 
    WarehouseInventory wi ON 1=1     
WHERE 
    ms.TotalSales > 0
ORDER BY 
    ms.SalesYear, ms.SalesMonth, cd.cd_gender, cd.cd_marital_status;