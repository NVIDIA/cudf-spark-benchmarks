
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        AVG(ws.ws_net_profit) AS Avg_Net_Profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS Unique_Customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.Total_Sales) AS Total_Sales,
        SUM(ss.Total_Orders) AS Total_Orders,
        AVG(ss.Avg_Net_Profit) AS Avg_Net_Profit
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.Unique_Customers = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.Total_Sales,
    cd.Total_Orders,
    cd.Avg_Net_Profit,
    ROW_NUMBER() OVER (ORDER BY cd.Total_Sales DESC) AS Sales_Rank
FROM 
    CustomerDemographics cd
ORDER BY 
    cd.Total_Sales DESC
LIMIT 10;
