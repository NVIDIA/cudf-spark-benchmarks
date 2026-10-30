WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_transactions
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND dd.d_month_seq IN (7, 8) 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        COUNT(cs.cs_order_number) AS catalog_transactions
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    sd.ws_item_sk,
    COALESCE(sd.total_sales, 0) AS web_total_sales,
    COALESCE(sd.total_net_profit, 0) AS web_total_net_profit,
    COALESCE(cd.total_catalog_sales, 0) AS catalog_total_sales,
    COALESCE(cd.catalog_transactions, 0) AS catalog_total_transactions,
    COALESCE(id.quantity_on_hand, 0) AS total_inventory
FROM 
    sales_data sd
FULL OUTER JOIN 
    customer_data cd ON sd.ws_item_sk = cd.c_customer_sk
FULL OUTER JOIN 
    inventory_data id ON sd.ws_item_sk = id.inv_item_sk
ORDER BY 
    web_total_sales DESC, catalog_total_sales DESC;