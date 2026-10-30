
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TotalSales AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
PromotionDetails AS (
    SELECT 
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
)
SELECT 
    ts.ca_city,
    ts.ca_state,
    ts.total_orders,
    ts.total_net_profit,
    pd.promo_order_count,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_net_profit,
    r.profit_rank,
    r.c_customer_id,
    r.ca_country,
    r.d_year,
    r.d_month_seq
FROM 
    TotalSales ts
LEFT JOIN 
    PromotionDetails pd ON ts.total_orders = pd.promo_order_count
JOIN 
    RankedSales r ON r.c_customer_id IS NOT NULL AND r.profit_rank = 1
WHERE 
    (ts.total_net_profit > 1000 OR pd.promo_order_count IS NULL)
ORDER BY 
    ts.total_net_profit DESC
LIMIT 100;
