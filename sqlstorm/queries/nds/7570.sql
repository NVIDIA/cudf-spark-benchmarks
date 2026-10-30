
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        SUM(total_quantity_sold) AS total_sold
    FROM 
        RankedSales
    WHERE 
        rank <= 10
    GROUP BY 
        ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM TopSellingItems)
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS high_value_customer_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    hvc.high_value_customer_count,
    ROUND(100.0 * hvc.high_value_customer_count / SUM(hvc.high_value_customer_count) OVER(), 2) AS percentage_of_high_value_customers
FROM 
    HighValueCustomers hvc
JOIN 
    customer_demographics cd ON hvc.cd_gender = cd.cd_gender;
