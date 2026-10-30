
WITH SalesAggregation AS (
    SELECT 
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_paid) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        AVG(ws.ws_net_profit) AS Average_Profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, i.i_category
),
SalesRanked AS (
    SELECT 
        d_year,
        i_category,
        Total_Sales,
        Total_Orders,
        Average_Profit,
        RANK() OVER (PARTITION BY d_year ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM 
        SalesAggregation
)
SELECT 
    d_year,
    i_category,
    Total_Sales,
    Total_Orders,
    Average_Profit,
    Sales_Rank
FROM 
    SalesRanked
WHERE 
    Sales_Rank <= 10
ORDER BY 
    d_year, Sales_Rank;
