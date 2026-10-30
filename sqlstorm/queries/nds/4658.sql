
WITH CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk, 
        total_orders, 
        total_profit, 
        avg_order_value
    FROM 
        CustomerOrderStats
    WHERE 
        profit_rank <= 10
),
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk, 
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
WebSalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ItemSalesComparison AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(ssd.total_sales_quantity, 0) AS in_store_sales,
        COALESCE(wsd.total_web_quantity, 0) AS online_sales,
        COALESCE(ssd.total_store_profit, 0) AS in_store_profit,
        COALESCE(wsd.total_web_profit, 0) AS online_profit
    FROM 
        item i
    LEFT JOIN 
        StoreSalesData ssd ON i.i_item_sk = ssd.ss_item_sk
    LEFT JOIN 
        WebSalesData wsd ON i.i_item_sk = wsd.ws_item_sk
)
SELECT 
    ivc.c_customer_sk,
    ivc.total_orders,
    ivc.total_profit,
    ivc.avg_order_value,
    isc.i_item_sk, 
    isc.i_item_desc,
    isc.in_store_sales,
    isc.online_sales,
    isc.in_store_profit,
    isc.online_profit,
    CASE 
        WHEN isc.in_store_profit > isc.online_profit THEN 'Higher in Store' 
        WHEN isc.in_store_profit < isc.online_profit THEN 'Higher Online' 
        ELSE 'Equal Profit'
    END AS profit_comparison
FROM 
    HighValueCustomers ivc
JOIN 
    ItemSalesComparison isc ON ivc.c_customer_sk = isc.i_item_sk
ORDER BY 
    ivc.total_profit DESC, 
    isc.i_item_desc;
