
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ship_day.d_date,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        date_dim AS ship_day
    JOIN 
        RankedSales AS rs ON ship_day.d_date_sk = rs.ws_ship_date_sk
    WHERE 
        ship_day.d_date >= '2023-01-01' AND ship_day.d_date <= '2023-12-31'
        AND rs.sales_rank <= 10
),
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ti.total_quantity,
    ti.total_sales,
    cs.c_customer_sk,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Purchase'
        WHEN cs.total_spent < 100 THEN 'Low Spender'
        WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Mid Spender'
        ELSE 'High Spender'
    END AS customer_segment
FROM 
    TopItems AS ti
LEFT JOIN 
    CustomerSpend AS cs ON ti.ws_item_sk = cs.c_customer_sk
WHERE 
    ti.total_quantity > 50
ORDER BY 
    ti.total_sales DESC, 
    cs.total_spent DESC;
