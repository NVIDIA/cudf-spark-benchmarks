
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ss.total_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        sales_summary ss ON ws.ws_item_sk = ss.ws_item_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender, 
        hd.hd_income_band_sk
), income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(total_spent) AS total_revenue
    FROM 
        customer_summary cs
    JOIN 
        income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customer_count,
    id.total_revenue
FROM 
    income_distribution id
JOIN 
    income_band ib ON id.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
