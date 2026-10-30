
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451875 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(h.hd_buy_potential, 'Unknown') AS buying_potential,
    SUM(sr.sr_return_quantity) AS total_returns,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    household_demographics h ON hvc.c_customer_sk = h.hd_demo_sk
LEFT JOIN 
    store_returns sr ON hvc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    hvc.profit_rank <= 10 
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, h.hd_buy_potential
ORDER BY 
    avg_net_paid DESC;
