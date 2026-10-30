
WITH SalesSummary AS (
    SELECT 
        d.d_year AS Year,
        s.s_store_name AS Store,
        SUM(ws.ws_quantity) AS Total_Quantity_Sold,
        SUM(ws.ws_sales_price) AS Total_Sales_Amount,
        AVG(ws.ws_net_profit) AS Average_Net_Profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_customer_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, s.s_store_name
),
TopStores AS (
    SELECT 
        Year,
        Store,
        Total_Quantity_Sold,
        Total_Sales_Amount,
        Average_Net_Profit,
        RANK() OVER (PARTITION BY Year ORDER BY Total_Sales_Amount DESC) AS Sales_Rank
    FROM 
        SalesSummary
)

SELECT 
    Year,
    Store,
    Total_Quantity_Sold,
    Total_Sales_Amount,
    Average_Net_Profit
FROM 
    TopStores
WHERE 
    Sales_Rank <= 5
ORDER BY 
    Year, Sales_Rank;
