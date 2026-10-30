
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sales_price > 50
),
CustomerInformation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_net_profit
    FROM 
        CustomerInformation ci
    WHERE 
        ci.total_net_profit > 1000
),
TopSoldItems AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
    HAVING 
        SUM(ws.ws_quantity) > 100
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    tsi.i_product_name,
    tsi.total_quantity_sold,
    COUNT(rs.ws_item_sk) AS purchase_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RankedSales rs ON hvc.c_customer_sk = rs.ws_bill_customer_sk
JOIN 
    TopSoldItems tsi ON rs.ws_item_sk = tsi.i_item_sk
WHERE 
    hvc.cd_gender IS NOT NULL
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, hvc.cd_gender, hvc.cd_marital_status, tsi.i_product_name, tsi.total_quantity_sold
ORDER BY 
    hvc.c_last_name ASC, hvc.c_first_name ASC;
