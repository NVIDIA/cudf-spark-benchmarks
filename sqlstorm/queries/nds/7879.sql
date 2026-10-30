
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sales_quantity,
        SUM(cs_ext_sales_price) AS total_sales_amount,
        AVG(cs_net_paid) AS average_net_price,
        MAX(cs_net_profit) AS max_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cs_item_sk
),
top_selling_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ss.total_sales_quantity,
        ss.total_sales_amount,
        ss.average_net_price,
        ss.max_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales_quantity DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.cs_item_sk = i.i_item_sk
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sales_quantity,
    tsi.total_sales_amount,
    tsi.average_net_price,
    tsi.max_profit
FROM 
    top_selling_items tsi
WHERE 
    tsi.sales_rank <= 10
ORDER BY 
    tsi.total_sales_quantity DESC;
