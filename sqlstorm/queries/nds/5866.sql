
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        rs.total_quantity, 
        rs.total_net_profit 
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_quantity,
    tp.total_net_profit,
    CASE 
        WHEN tp.total_net_profit > 10000 THEN 'High Profit'
        WHEN tp.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    TopProducts tp
ORDER BY 
    tp.total_net_profit DESC;
