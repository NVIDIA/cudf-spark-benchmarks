
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
),
IncomeDistribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        ROUND(AVG(cs.total_profit), 2) AS avg_profit
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    id.customer_count,
    id.avg_profit
FROM 
    TopCustomers tc
LEFT JOIN 
    IncomeDistribution id ON (tc.profit_rank <= 10 AND id.hd_income_band_sk IS NOT NULL)
WHERE 
    id.customer_count > 0 
ORDER BY 
    tc.total_profit DESC;
