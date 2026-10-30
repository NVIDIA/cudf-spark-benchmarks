
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        r.total_quantity,
        r.total_profit
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
Combined AS (
    SELECT 
        ti.i_item_id,
        ti.i_product_name,
        cs.c_customer_id,
        cs.customer_profit,
        ti.total_quantity,
        ti.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_id ORDER BY ti.total_profit DESC) AS row_num
    FROM 
        TopItems ti
    JOIN 
        CustomerSales cs ON cs.customer_profit > 0
)
SELECT 
    i_item_id AS item_id,
    i_product_name AS product_name,
    c_customer_id AS customer_id,
    customer_profit,
    total_quantity,
    total_profit
FROM 
    Combined
WHERE 
    row_num = 1
ORDER BY 
    total_profit DESC;
