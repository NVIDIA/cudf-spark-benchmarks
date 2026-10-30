
WITH TotalSales AS (
    SELECT
        d.d_year AS Year,
        i.i_category AS Category,
        SUM(ws.ws_quantity) AS Total_Quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS Total_Sales,
        AVG(ws.ws_net_profit) AS Avg_Net_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Order_Count
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY
        d.d_year,
        i.i_category
),
SalesRanking AS (
    SELECT
        Year,
        Category,
        Total_Quantity,
        Total_Sales,
        Avg_Net_Profit,
        Order_Count,
        RANK() OVER (PARTITION BY Year ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM
        TotalSales
)
SELECT
    Year,
    Category,
    Total_Quantity,
    Total_Sales,
    Avg_Net_Profit,
    Order_Count,
    Sales_Rank
FROM
    SalesRanking
WHERE
    Sales_Rank <= 10
ORDER BY
    Year,
    Sales_Rank;
