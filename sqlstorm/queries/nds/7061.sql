
WITH aggregated_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_order_quantity,
        MAX(ws.ws_sales_price) AS max_order_price,
        MIN(ws.ws_sales_price) AS min_order_price,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
), ranked_sales AS (
    SELECT 
        *,
        CASE 
            WHEN profit_rank <= 10 THEN 'Top 10%'
            WHEN profit_rank <= 25 THEN 'Top 25%'
            WHEN profit_rank <= 50 THEN 'Top 50%'
            ELSE 'Rest'
        END AS profit_bracket
    FROM 
        aggregated_sales
)
SELECT 
    profit_bracket,
    COUNT(*) AS customer_count,
    SUM(total_net_profit) AS total_net_profit,
    AVG(avg_order_quantity) AS avg_quantity_per_order,
    MAX(max_order_price) AS highest_single_order_value,
    MIN(min_order_price) AS lowest_single_order_value
FROM 
    ranked_sales
GROUP BY 
    profit_bracket
ORDER BY 
    profit_bracket;
