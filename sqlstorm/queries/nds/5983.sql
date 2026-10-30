
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_id, d.d_year
), customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
), return_summary AS (
    SELECT 
        r.r_reason_desc,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_net_profit,
    cs.customer_count,
    cs.avg_purchase_estimate,
    rs.total_returns,
    rs.total_return_amount
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_orders > cs.customer_count / 10
JOIN 
    return_summary rs ON rs.total_returns > 100
ORDER BY 
    ss.total_net_profit DESC, cs.customer_count DESC;
