
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        w.w_warehouse_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS item_net_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_net_profit) > 100
),
Summary AS (
    SELECT 
        s.w_warehouse_name AS warehouse_name,
        SUM(s.total_quantity_sold) AS total_quantity,
        AVG(cd.customer_count) AS avg_customers,
        SUM(ts.item_net_profit) AS total_item_profit
    FROM 
        SalesSummary s
    LEFT JOIN 
        CustomerDemographics cd ON s.total_orders > 0
    LEFT JOIN 
        TopSales ts ON ts.profit_rank <= 10
    GROUP BY 
        s.w_warehouse_name
)
SELECT 
    warehouse_name,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(avg_customers, 0) AS avg_customers,
    COALESCE(total_item_profit, 0) AS total_item_profit
FROM 
    Summary
ORDER BY 
    warehouse_name
;
