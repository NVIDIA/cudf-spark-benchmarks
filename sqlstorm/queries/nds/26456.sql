
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        LENGTH(i.i_item_desc) AS desc_length,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(i.i_item_desc, 1, 1) ORDER BY LENGTH(i.i_item_desc) DESC) AS rank
    FROM item i
    WHERE i.i_item_desc IS NOT NULL
),
TopItems AS (
    SELECT 
        ri.i_item_id,
        ri.i_item_desc,
        ri.desc_length,
        ri.i_current_price
    FROM RankedItems ri
    WHERE ri.rank <= 5
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
FinalReport AS (
    SELECT 
        cs.full_name,
        cs.total_quantity,
        cs.total_spent,
        ti.i_item_id,
        ti.i_item_desc,
        ti.desc_length,
        ti.i_current_price
    FROM CustomerSummary cs
    JOIN TopItems ti ON cs.total_quantity > 0
    ORDER BY cs.total_spent DESC, ti.desc_length DESC
    LIMIT 10
)
SELECT * FROM FinalReport;
