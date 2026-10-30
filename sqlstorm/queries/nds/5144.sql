
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_desc,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc, i.i_category
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.i_item_desc,
        rs.total_sales,
        rs.total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ts.total_sales) AS total_spent
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    TopSellingItems ts ON ws.ws_item_sk = ts.ws_item_sk
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_spent DESC
LIMIT 20;
