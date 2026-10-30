
WITH RecentSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spent > 0
)
SELECT 
    rc.ws_order_number,
    rc.ws_item_sk,
    rc.ws_sales_price,
    rc.ws_ext_sales_price,
    rc.ws_quantity,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.spend_rank
FROM 
    RecentSales rc
JOIN 
    TopCustomers tc ON rc.ws_order_number = tc.c_customer_sk
WHERE 
    rc.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 50)
    AND tc.spend_rank <= 10
ORDER BY 
    rc.ws_ext_sales_price DESC;
