
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY i_category ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        ws_item_sk, i_category
), TopProducts AS (
    SELECT 
        i_category, 
        i_product_name, 
        total_quantity, 
        total_profit,
        ws_item_sk  -- Added ws_item_sk to group by
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        profit_rank <= 10
), DailySummary AS (
    SELECT 
        d.d_date,
        SUM(tp.total_quantity) AS total_quantity_sold,
        SUM(tp.total_profit) AS total_profit_generated
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        TopProducts tp ON ws.ws_item_sk = tp.ws_item_sk 
    GROUP BY 
        d.d_date
), TotalPerformance AS (
    SELECT 
        SUM(total_quantity_sold) AS cumulative_quantity,
        SUM(total_profit_generated) AS cumulative_profit
    FROM 
        DailySummary
)
SELECT 
    dp.d_date,
    dp.total_quantity_sold,
    dp.total_profit_generated,
    (tp.cumulative_profit + dp.total_profit_generated) AS running_total_profit
FROM 
    DailySummary dp
CROSS JOIN 
    TotalPerformance tp
ORDER BY 
    dp.d_date;
