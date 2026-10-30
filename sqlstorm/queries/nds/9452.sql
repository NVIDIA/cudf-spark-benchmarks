
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_profit DESC
    LIMIT 10
), 
monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
), 
state_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
), 
promotional_analysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    ss.ca_state,
    ss.num_customers,
    ss.total_profit AS state_profit,
    pa.p_promo_name,
    pa.order_count,
    pa.total_sales AS promo_sales
FROM 
    top_customers tc
JOIN 
    monthly_sales ms ON ms.total_sales > 10000
JOIN 
    state_summary ss ON ss.total_profit > 50000
JOIN 
    promotional_analysis pa ON pa.total_sales > 1000
ORDER BY 
    tc.total_profit DESC, 
    ms.d_year DESC, 
    ss.total_profit DESC;
