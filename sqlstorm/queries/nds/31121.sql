
WITH  SalesCTE AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
TopSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_net_profit) > (
            SELECT 
                AVG(total_profit) 
            FROM 
                SalesCTE
            WHERE 
                profit_rank <= 10
        )
),
MonthlySales AS (
    SELECT 
        dd.d_month_seq,
        SUM(ts.total_quantity) AS month_sales,
        SUM(ts.total_net_profit) AS month_profit
    FROM 
        TopSales ts
    JOIN 
        date_dim dd ON ts.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_month_seq
)
SELECT 
    md.d_month_seq, 
    ms.month_sales, 
    ms.month_profit,
    CASE
        WHEN ms.month_profit IS NULL THEN 'No Data'
        WHEN ms.month_profit = 0 THEN 'Zero Profit'
        ELSE 'Profit Generated'
    END AS profit_status
FROM 
    MonthlySales ms
RIGHT OUTER JOIN 
    date_dim md ON ms.d_month_seq = md.d_month_seq 
WHERE 
    md.d_year = 2023
ORDER BY 
    md.d_month_seq;
