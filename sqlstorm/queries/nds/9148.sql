
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND it.i_current_price > 50.00
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
), 
top_items AS (
    SELECT 
        si.i_item_id,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS sales_rank
    FROM 
        sales_data sd
    JOIN 
        item si ON sd.ws_item_sk = si.i_item_sk
)
SELECT 
    ti.i_item_id,
    ti.total_quantity,
    ti.total_sales,
    ti.total_discount,
    ti.total_profit
FROM 
    top_items ti
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_profit DESC;
