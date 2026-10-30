
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        cs.cs_item_sk
),
DemographicsData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender = 'M'
    GROUP BY 
        cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_profit,
        sd.avg_sales_price,
        dd.customer_count,
        dd.avg_purchase_estimate
    FROM 
        SalesData sd
    LEFT JOIN 
        DemographicsData dd ON sd.cs_item_sk = dd.cd_demo_sk
)
SELECT 
    fr.cs_item_sk AS Item_SK,
    fr.total_quantity AS Total_Quantity_Sold,
    fr.total_profit AS Total_Profit,
    fr.avg_sales_price AS Average_Sales_Price,
    COALESCE(fr.customer_count, 0) AS Customer_Count,
    COALESCE(fr.avg_purchase_estimate, 0) AS Average_Purchase_Estimate
FROM 
    FinalReport fr
ORDER BY 
    fr.total_profit DESC
LIMIT 100;
