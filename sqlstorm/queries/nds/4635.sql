
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2022
), 
AggregatedSales AS (
    SELECT 
        i.i_item_id AS item_id,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        COUNT(sd.ws_sold_date_sk) AS sales_count
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        i.i_item_id
), 
TopProfitableItems AS (
    SELECT 
        item_id,
        total_quantity,
        total_net_profit,
        avg_sales_price,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        AggregatedSales
)
SELECT 
    ti.item_id,
    ti.total_quantity,
    ti.total_net_profit,
    ti.avg_sales_price,
    CASE 
        WHEN ti.total_net_profit IS NULL THEN 'No Profit' 
        ELSE 'Profitable' 
    END AS profit_status
FROM 
    TopProfitableItems ti
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    ti.total_net_profit DESC;
