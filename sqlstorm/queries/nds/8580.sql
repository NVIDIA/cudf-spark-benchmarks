
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_month_seq,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws.ws_item_sk, d.d_month_seq, d.d_year, i.i_category, i.i_brand
),
RankedSales AS (
    SELECT 
        ws_item_sk AS item_sk, 
        total_quantity_sold, 
        total_sales, 
        total_profit,
        d_year,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    rs.d_year,
    COUNT(*) AS top_selling_items,
    SUM(rs.total_sales) AS total_sales,
    SUM(rs.total_profit) AS total_profit
FROM 
    RankedSales rs
WHERE 
    rs.profit_rank <= 10
GROUP BY 
    rs.d_year
ORDER BY 
    rs.d_year;
