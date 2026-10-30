
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk, ss_item_sk
), 
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_item_sk) AS rn
    FROM 
        item
    WHERE 
        i_current_price IS NOT NULL
), 
DateFilter AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq
    FROM 
        date_dim 
    WHERE 
        d_year = (SELECT MAX(d_year) FROM date_dim)
)
SELECT 
    sa.ss_store_sk,
    sa.total_quantity,
    sa.total_profit,
    id.i_item_desc,
    id.i_current_price,
    CASE 
        WHEN sa.total_quantity IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status,
    RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank,
    COALESCE((SELECT AVG(total_profit) FROM SalesCTE WHERE total_profit > 50), 0) AS avg_high_profit,
    MAX(df.d_month_seq) AS year_sequence
FROM 
    SalesCTE sa
LEFT JOIN 
    ItemDetails id ON sa.ss_item_sk = id.i_item_sk 
FULL OUTER JOIN 
    DateFilter df ON df.d_date_sk = sa.ss_store_sk
WHERE 
    (sa.total_profit IS NOT NULL OR id.i_current_price > 100)
    AND (df.d_year IS NOT NULL OR id.i_item_desc IS NOT NULL)
GROUP BY 
    sa.ss_store_sk, sa.total_quantity, sa.total_profit, 
    id.i_item_desc, id.i_current_price
ORDER BY 
    sa.total_profit DESC NULLS LAST 
LIMIT 10;
