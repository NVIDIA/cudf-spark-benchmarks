
WITH sales_data AS (
    SELECT 
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk) AS sold_date_sk,
        COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_profit
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        sold_date_sk, item_sk
),
date_aggregation AS (
    SELECT 
        dd.d_year,
        sd.sold_date_sk,
        SUM(sd.total_quantity) AS total_sold_quantity,
        SUM(sd.total_profit) AS total_sold_profit
    FROM 
        sales_data sd
    JOIN 
        date_dim dd ON sd.sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, sd.sold_date_sk
),
yearly_summary AS (
    SELECT 
        d_year,
        SUM(total_sold_quantity) AS yearly_quantity,
        SUM(total_sold_profit) AS yearly_profit
    FROM 
        date_aggregation
    GROUP BY 
        d_year
)
SELECT 
    ys.d_year,
    ys.yearly_quantity,
    ys.yearly_profit,
    ROW_NUMBER() OVER (ORDER BY ys.yearly_profit DESC) AS profit_rank
FROM 
    yearly_summary ys
WHERE 
    ys.yearly_profit > 0
ORDER BY 
    ys.yearly_profit DESC, ys.yearly_quantity DESC;
