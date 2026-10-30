
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS RankProfit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
TopSales AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_sales_price) AS TotalSales,
        SUM(sd.ws_net_profit) AS TotalProfit
    FROM 
        SalesData sd
    JOIN 
        item item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.RankProfit <= 5
    GROUP BY 
        item.i_item_id
)
SELECT 
    ts.i_item_id,
    ts.TotalSales,
    ts.TotalProfit,
    CASE 
        WHEN ts.TotalProfit > 10000 THEN 'High Profit'
        WHEN ts.TotalProfit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS ProfitCategory
FROM 
    TopSales ts
ORDER BY 
    ts.TotalProfit DESC;
