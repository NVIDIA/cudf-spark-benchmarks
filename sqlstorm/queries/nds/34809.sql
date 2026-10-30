
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
RankedSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS customer_spend
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS web_net_profit,
    COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
FROM 
    CustomerSales cs
LEFT JOIN 
    web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
FULL OUTER JOIN 
    store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
WHERE 
    cs.customer_spend > (SELECT AVG(customer_spend) FROM CustomerSales)
GROUP BY 
    cs.c_customer_sk, cs.c_first_name, cs.c_last_name
HAVING 
    COALESCE(SUM(ws.ws_net_profit), 0) > 1000 OR COALESCE(SUM(ss.ss_net_profit), 0) > 1000
ORDER BY 
    web_net_profit DESC, store_net_profit ASC;
