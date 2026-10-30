
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_value,
        SUM(ws_coupon_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT 
        ss.ss_item_sk, 
        ss.ss_sales_price,
        ss.ss_net_profit,
        s.total_quantity_sold,
        s.total_sales_value,
        s.total_discount,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        store_sales ss
    JOIN 
        SalesSummary s ON ss.ss_item_sk = s.ws_item_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        s.rn <= 5 
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.total_orders,
        cs.avg_profit_per_order,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerStats cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    h.c_customer_sk,
    h.total_spent,
    h.total_orders,
    h.avg_profit_per_order,
    ti.i_item_desc,
    ti.i_brand,
    ti.total_quantity_sold,
    ti.total_sales_value,
    ti.total_discount
FROM 
    HighSpenders h
FULL OUTER JOIN 
    TopItems ti ON h.total_orders = ti.total_quantity_sold
WHERE 
    h.avg_profit_per_order > 0 OR ti.ss_item_sk IS NULL
ORDER BY 
    h.total_spent DESC, ti.total_sales_value DESC;
