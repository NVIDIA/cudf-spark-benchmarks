
WITH CustomerSalesData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS total_unique_items,
        MAX(ws.ws_ship_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
RankedCustomerSales AS (
    SELECT 
        csd.c_customer_id,
        csd.cd_gender,
        csd.cd_marital_status,
        csd.total_net_profit,
        csd.total_orders,
        csd.total_unique_items,
        csd.last_order_date,
        RANK() OVER (PARTITION BY csd.cd_gender ORDER BY csd.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSalesData csd
)
SELECT 
    rcs.c_customer_id,
    rcs.cd_gender,
    rcs.cd_marital_status,
    rcs.total_net_profit,
    rcs.total_orders,
    rcs.total_unique_items,
    rcs.last_order_date
FROM 
    RankedCustomerSales rcs
WHERE 
    rcs.profit_rank <= 10
ORDER BY 
    rcs.cd_gender, rcs.total_net_profit DESC;
