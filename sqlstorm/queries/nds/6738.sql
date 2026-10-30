
WITH sales_summary AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        d.d_week_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND p.p_discount_active = 'Y'
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq
), inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    ss.d_year, 
    ss.d_month_seq, 
    ss.d_week_seq,
    ss.total_sales, 
    ss.total_orders, 
    ss.total_quantity, 
    ss.average_profit, 
    COALESCE(i.total_inventory, 0) AS total_inventory
FROM 
    sales_summary AS ss
LEFT JOIN 
    inventory_summary AS i ON ss.d_week_seq = i.inv_warehouse_sk
ORDER BY 
    ss.d_year, ss.d_month_seq, ss.d_week_seq;
