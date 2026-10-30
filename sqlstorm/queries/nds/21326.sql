
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.ws_net_profit,
        COALESCE(rs.quantity_rank, 0) AS sales_rank
    FROM 
        item
    LEFT JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.profit_rank = 1
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
NullLogicExample AS (
    SELECT 
        c.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_orders IS NULL THEN 'No Orders'
            WHEN cs.total_orders > 0 AND cs.total_spent IS NULL THEN 'Spent Zero'
            ELSE 'Active Customer'
        END AS customer_status,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN cs.total_orders IS NULL THEN 'No Orders'
                WHEN cs.total_orders > 0 AND cs.total_spent IS NULL THEN 'Spent Zero'
                ELSE 'Active Customer'
            END 
            ORDER BY cs.total_spent DESC) AS status_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
FinalResults AS (
    SELECT 
        hi.i_item_id,
        hi.i_item_desc,
        nl.c_customer_sk,
        nl.customer_status,
        nl.status_rank
    FROM 
        HighProfitItems hi
    JOIN 
        NullLogicExample nl ON nl.c_customer_sk IS NOT NULL
    WHERE 
        nl.customer_status = 'Active Customer'
)

SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.c_customer_sk,
    f.customer_status,
    f.status_rank
FROM 
    FinalResults f
WHERE 
    f.status_rank <= 10 
ORDER BY 
    f.i_item_id, f.c_customer_sk;
