
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                    (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerProfit AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(rs.ws_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighProfitCustomers AS (
    SELECT 
        cp.c_customer_id,
        cp.total_profit,
        DENSE_RANK() OVER (ORDER BY cp.total_profit DESC) AS profit_rank
    FROM 
        CustomerProfit cp
    WHERE 
        cp.total_profit > (SELECT AVG(total_profit) FROM CustomerProfit)
)
SELECT 
    hpc.c_customer_id,
    hpc.total_profit,
    COALESCE(address.ca_city, 'Unknown') AS city,
    CEIL(RANDOM() * 100) AS random_segment,
    CASE 
        WHEN hpc.total_profit > 1000 THEN 'High'
        WHEN hpc.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    HighProfitCustomers hpc
LEFT JOIN 
    customer_address address ON hpc.c_customer_id = address.ca_address_id
WHERE 
    hpc.profit_rank <= 10
ORDER BY 
    hpc.total_profit DESC;
