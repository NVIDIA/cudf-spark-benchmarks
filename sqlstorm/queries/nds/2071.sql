
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), return_summary AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
), promo_summary AS (
    SELECT 
        ps.p_promo_id,
        COUNT(ps.p_promo_sk) AS promo_count,
        SUM(ps.p_cost) AS total_cost
    FROM 
        promotion ps
    WHERE 
        ps.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ps.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ps.p_promo_id
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ss.total_quantity_sold,
    ss.total_net_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(ps.promo_count, 0) AS promo_count,
    COALESCE(ps.total_cost, 0) AS total_promo_cost
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk IN (
        SELECT i.i_item_sk 
        FROM item i 
        WHERE i.i_current_price > 50 
        AND i.i_color IS NOT NULL
    )
LEFT JOIN 
    return_summary rs ON ss.ws_item_sk = rs.wr_item_sk
LEFT JOIN 
    promo_summary ps ON ps.promo_count > 0
WHERE 
    c.c_birth_year < 1990 
    AND c.c_preferred_cust_flag = 'Y'
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
