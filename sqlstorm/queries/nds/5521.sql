
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_net_profit DESC) AS rank_within_gender
    FROM 
        SalesData
)
SELECT 
    gender,
    AVG(total_net_profit) AS avg_profit_per_gender,
    SUM(total_orders) AS total_orders_by_gender,
    COUNT(*) AS number_of_customers,
    MIN(ib_lower_bound) AS min_income_band,
    MAX(ib_upper_bound) AS max_income_band
FROM 
    RankedSales
WHERE 
    rank_within_gender <= 10
GROUP BY 
    gender
ORDER BY 
    avg_profit_per_gender DESC;
