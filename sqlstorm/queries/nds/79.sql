
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01')
        AND (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31')
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesStats AS (
    SELECT 
        ci.c_customer_id,
        ci.total_spent,
        CASE 
            WHEN ci.total_spent IS NULL THEN 'No Purchases'
            WHEN ci.total_spent < 1000 THEN 'Low Spender'
            WHEN ci.total_spent < 5000 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM 
        CustomerSales ci
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(ss.c_customer_id, 'No Customer') AS customer_id,
    ss.total_spent,
    ss.spending_category
FROM 
    TopItems ti
LEFT JOIN 
    SalesStats ss ON ss.total_spent = (
        SELECT MAX(total_spent) FROM SalesStats
        WHERE spending_category = (
            SELECT MAX(spending_category) FROM SalesStats
        )
    )
ORDER BY 
    ti.total_sales DESC, 
    ss.total_spent DESC;
