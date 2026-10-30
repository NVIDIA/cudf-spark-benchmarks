
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_item_desc LIKE '%widget%'
    GROUP BY 
        i.i_item_id, i.i_item_desc, i.i_current_price
),
AggregateCustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
CustomerOrderDetails AS (
    SELECT 
        acd.c_customer_id,
        acd.cd_gender,
        ri.i_item_id,
        ri.i_item_desc,
        ri.i_current_price,
        acd.total_orders,
        acd.total_spent,
        ROW_NUMBER() OVER (PARTITION BY acd.c_customer_id ORDER BY acd.total_spent DESC) AS customer_rank
    FROM 
        AggregateCustomerData acd
    JOIN 
        RankedItems ri ON acd.total_orders > 0
)
SELECT 
    cod.c_customer_id,
    cod.cd_gender,
    cod.i_item_id,
    cod.i_item_desc,
    cod.i_current_price,
    cod.total_orders,
    cod.total_spent
FROM 
    CustomerOrderDetails cod
WHERE 
    cod.customer_rank <= 5
ORDER BY 
    cod.total_spent DESC, cod.i_item_id;
