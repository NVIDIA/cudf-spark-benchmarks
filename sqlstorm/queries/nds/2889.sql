
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY rs.total_net_profit DESC) AS overall_rnk
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rnk = 1
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) as rank_spent
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    ths.ws_item_sk,
    ths.total_quantity,
    ths.total_net_profit,
    ths.i_item_desc,
    COALESCE(hvc.order_count, 0) AS high_value_order_count,
    COALESCE(hvc.total_spent, 0) AS high_value_total_spent
FROM 
    TopSales ths
FULL OUTER JOIN 
    HighValueCustomers hvc ON ths.ws_item_sk = hvc.c_customer_sk
WHERE 
    ths.overall_rnk <= 10 
    OR hvc.rank_spent IS NOT NULL
ORDER BY 
    ths.total_net_profit DESC, hvc.total_spent DESC;
