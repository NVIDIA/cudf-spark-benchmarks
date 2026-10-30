
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),

returns_data AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),

item_summary AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
),

final_summary AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_loss, 0) AS total_return_loss,
        CASE 
            WHEN COALESCE(sd.total_quantity, 0) > 0 THEN ROUND((COALESCE(sd.total_net_profit, 0)/COALESCE(sd.total_quantity, 0)), 2)
            ELSE 0 
        END AS avg_net_profit_per_unit,
        CASE 
            WHEN COALESCE(rd.total_returns, 0) > 0 THEN ROUND((COALESCE(rd.total_return_loss, 0)/COALESCE(rd.total_returns, 0)), 2)
            ELSE 0 
        END AS avg_loss_per_return
    FROM 
        item_summary i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        returns_data rd ON i.i_item_sk = rd.wr_item_sk
)

SELECT 
    f.i_item_sk,
    f.i_item_desc,
    f.i_brand,
    f.total_quantity,
    f.total_net_profit,
    f.total_returns,
    f.total_return_loss,
    f.avg_net_profit_per_unit,
    f.avg_loss_per_return
FROM 
    final_summary f
ORDER BY 
    f.total_net_profit DESC
LIMIT 100;
