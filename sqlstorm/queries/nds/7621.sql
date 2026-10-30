
WITH SalesSummary AS (
    SELECT 
        d.d_year AS Year,
        d.d_month_seq AS Month,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS Unique_Customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender AS Gender,
        cd.cd_marital_status AS Marital_Status,
        COUNT(DISTINCT c.c_customer_sk) AS Customer_Count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id AS Warehouse_ID,
        SUM(ws.ws_net_profit) AS Net_Profit,
        AVG(ws.ws_net_paid) AS Avg_Net_Paid
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        ss.Year,
        ss.Month,
        ss.Total_Net_Profit,
        ss.Total_Orders,
        ss.Unique_Customers,
        cd.Gender,
        cd.Marital_Status,
        cd.Customer_Count,
        wp.Warehouse_ID,
        wp.Net_Profit,
        wp.Avg_Net_Paid
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDemographics cd ON ss.Total_Orders > 0
    CROSS JOIN 
        WarehousePerformance wp
)
SELECT 
    Year,
    Month,
    Total_Net_Profit,
    Total_Orders,
    Unique_Customers,
    Gender,
    Marital_Status,
    Customer_Count,
    Warehouse_ID,
    Net_Profit,
    Avg_Net_Paid
FROM 
    FinalReport
ORDER BY 
    Year, Month, Gender, Marital_Status, Warehouse_ID;
