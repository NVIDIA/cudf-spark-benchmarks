
WITH RankedReturns AS (
    SELECT 
        sr_cdemo_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_cdemo_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
ItemSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales,
        COUNT(ws_order_number) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_sales > 5000
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rr.sr_item_sk,
    rr.sr_return_quantity,
    ist.total_sold,
    tr.sales_rank
FROM 
    TopCustomers tr
JOIN 
    CustomerStats rc ON rc.c_customer_sk = tr.c_customer_sk
LEFT JOIN 
    RankedReturns rr ON rc.c_customer_sk = rr.sr_cdemo_sk AND rr.rn = 1
LEFT JOIN 
    ItemSales ist ON rr.sr_item_sk = ist.ws_item_sk
WHERE 
    rc.num_orders > 10 AND 
    (rc.cd_gender = 'F' OR (rc.cd_marital_status IS NULL AND rc.c_first_name LIKE '%e%'))
ORDER BY 
    rc.total_sales DESC, rr.sr_return_quantity DESC NULLS LAST;
