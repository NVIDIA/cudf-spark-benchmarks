
WITH TopSellingItems AS (
    SELECT 
        i.i_item_id,
        SUM(cs.cs_quantity) AS total_sold_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_value
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_sales_value DESC
    LIMIT 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ci.c_customer_id,
    ci.total_orders,
    ci.total_net_profit,
    tsi.total_sold_quantity,
    tsi.total_sales_value
FROM 
    CustomerInfo ci
JOIN 
    TopSellingItems tsi ON ci.total_orders > 0
ORDER BY 
    ci.total_net_profit DESC, tsi.total_sales_value DESC
LIMIT 15;
