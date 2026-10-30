
WITH sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_sales_price) AS total_sales_value,
        MAX(cs.cs_sold_date_sk) AS last_sale_date
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
top_sales AS (
    SELECT 
        ss.cs_item_sk,
        ss.total_quantity_sold,
        ss.total_net_profit,
        ss.total_sales_value,
        i.i_item_desc,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.cs_item_sk = i.i_item_sk
)
SELECT 
    ts.rank,
    ts.i_item_desc,
    ts.total_quantity_sold,
    ts.total_net_profit,
    ts.total_sales_value
FROM 
    top_sales ts
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.rank;
