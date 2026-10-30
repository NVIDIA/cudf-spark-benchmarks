WITH sales_summary AS (
    SELECT 
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458332 AND 2459000 
    GROUP BY 
        cd.cd_gender, hd.hd_income_band_sk
),
average_sales AS (
    SELECT 
        cd_gender,
        hd_income_band_sk,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_profit) AS avg_profit,
        AVG(total_orders) AS avg_orders
    FROM 
        sales_summary
    GROUP BY 
        cd_gender, hd_income_band_sk
)
SELECT 
    ab.cd_gender,
    ab.hd_income_band_sk,
    ab.avg_quantity,
    ab.avg_profit,
    ab.avg_orders,
    RANK() OVER (PARTITION BY ab.cd_gender ORDER BY ab.avg_profit DESC) AS profit_rank
FROM 
    average_sales ab
ORDER BY 
    ab.cd_gender, profit_rank;