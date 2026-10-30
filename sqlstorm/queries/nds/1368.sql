
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND ws.ws_net_profit IS NOT NULL
),
TopSales AS (
    SELECT 
        sd.i_category,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 10
    GROUP BY 
        sd.i_category
),
SalesTrend AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS monthly_sales,
        SUM(ws.ws_quantity) AS monthly_quantity,
        SUM(ws.ws_net_profit) AS monthly_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
    GROUP BY 
        d.d_month_seq
)
SELECT 
    t.i_category,
    t.total_profit,
    s.monthly_sales,
    s.monthly_quantity,
    s.monthly_net_profit,
    CASE 
        WHEN s.monthly_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded' 
    END AS sales_status
FROM 
    TopSales t
LEFT JOIN 
    SalesTrend s ON t.i_category = (
        SELECT i.i_category 
        FROM item i 
        WHERE i.i_item_sk = (
            SELECT ws.ws_item_sk 
            FROM web_sales ws 
            WHERE ws.ws_order_number = (
                SELECT ws.ws_order_number 
                FROM web_sales ws 
                ORDER BY ws.ws_net_profit DESC 
                LIMIT 1
            ) 
            LIMIT 1
        )
        LIMIT 1
    )
ORDER BY 
    t.total_profit DESC;
