
WITH  Sales_CTE AS (
    SELECT 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
    UNION ALL
    SELECT 
        cs_order_number, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_order_number
),
Return_CTE AS (
    SELECT 
        sr_ticket_number, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_ticket_number
),
Customer_CTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(rc.total_returned), 0) AS total_returned_amount,
        COUNT(DISTINCT p.p_promo_name) AS promo_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        Return_CTE rc ON ws.ws_order_number = rc.sr_ticket_number
    LEFT JOIN 
        promotion p ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    cc.c_first_name,
    cc.c_last_name,
    cc.total_orders,
    cc.total_net_profit,
    cc.total_returned_amount,
    cc.promo_count,
    NTILE(4) OVER (ORDER BY cc.total_net_profit DESC) AS profit_quartile
FROM 
    Customer_CTE cc
WHERE 
    cc.total_orders > 0
ORDER BY 
    cc.total_net_profit DESC;
