
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        ws.ws_sales_price,
        COALESCE(ws.ws_net_paid, 0) AS total_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.total_paid) AS total_revenue,
        MAX(rs.ws_sales_price) AS max_price,
        MIN(rs.ws_sales_price) AS min_price
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
SalesByDay AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        dd.d_date
),
TopDays AS (
    SELECT 
        sbd.d_date,
        sbd.total_quantity,
        sbd.total_profit,
        RANK() OVER (ORDER BY sbd.total_profit DESC) AS profit_rank
    FROM 
        SalesByDay sbd
)
SELECT 
    hpi.ws_item_sk,
    hpi.total_revenue,
    hpi.max_price,
    hpi.min_price,
    td.d_date,
    td.total_quantity,
    td.total_profit,
    CASE 
        WHEN td.profit_rank = 1 THEN 'Top Day'
        ELSE 'Regular Day'
    END AS sales_day_category
FROM 
    HighProfitItems hpi
LEFT JOIN 
    TopDays td ON td.total_quantity > 100
WHERE 
    hpi.total_revenue > (SELECT AVG(total_revenue) FROM HighProfitItems)
ORDER BY 
    hpi.total_revenue DESC, td.total_profit DESC;
