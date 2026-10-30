
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
SalesSummary AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales_price
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent IS NOT NULL
)
SELECT 
    ws.ws_item_sk,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    total_sales.total_sales_price AS last_sales_price,
    tc.c_customer_sk,
    tc.total_spent,
    tc.rank
FROM 
    web_sales ws
JOIN 
    SalesSummary total_sales ON ws.ws_item_sk = total_sales.ws_item_sk
LEFT JOIN 
    TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
GROUP BY 
    ws.ws_item_sk, total_sales.total_sales_price, tc.c_customer_sk, tc.total_spent, tc.rank
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_quantity_sold DESC, last_sales_price DESC;
