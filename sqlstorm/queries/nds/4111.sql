
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk, 
        ws_item_sk
),
HighSpendingCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_quantity,
        total_net_paid
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        total_net_paid > 1000
),
CustomerCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT rs.ws_item_sk) AS item_count
    FROM 
        customer c
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hsc.c_customer_sk,
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_quantity,
    hsc.total_net_paid,
    COALESCE(cc.item_count, 0) AS distinct_items_purchased
FROM 
    HighSpendingCustomers hsc
LEFT JOIN 
    CustomerCounts cc ON hsc.c_customer_sk = cc.c_customer_sk
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store_sales ss
        WHERE ss.ss_customer_sk = hsc.c_customer_sk
        AND ss.ss_sales_price < 50
    )
ORDER BY 
    hsc.total_net_paid DESC
LIMIT 10;
