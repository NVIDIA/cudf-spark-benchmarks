WITH sales_summary AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_quantity) AS total_units_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2001 
        AND (cd.cd_marital_status = 'M' AND cd.cd_gender = 'F') 
        AND ca.ca_state = 'CA'
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date), EXTRACT(MONTH FROM d.d_date)
),
promotion_details AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.total_units_sold,
    ss.total_net_profit,
    pp.promo_net_profit,
    wp.total_quantity_sold,
    wp.total_profit
FROM 
    sales_summary ss
JOIN 
    promotion_details pp ON ss.sales_month = EXTRACT(MONTH FROM cast('2002-10-01' as date))
JOIN 
    warehouse_performance wp ON wp.total_profit > 1000
ORDER BY 
    ss.sales_year DESC, ss.sales_month DESC;