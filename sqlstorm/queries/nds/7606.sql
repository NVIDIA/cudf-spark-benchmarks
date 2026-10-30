
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_purchase
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_purchase,
        RANK() OVER (ORDER BY cp.total_purchase DESC) AS customer_rank
    FROM 
        CustomerPurchases cp
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    rc.ws_item_sk,
    rc.total_quantity,
    rc.total_profit,
    tc.customer_rank,
    wp.total_sales_profit,
    wp.sales_count
FROM 
    RankedSales rc
JOIN 
    TopCustomers tc ON rc.rank = 1
JOIN 
    WarehousePerformance wp ON wp.total_sales_profit > 10000
WHERE 
    rc.total_profit > 5000
ORDER BY 
    rc.total_quantity DESC, wp.total_sales_profit DESC
LIMIT 50;
