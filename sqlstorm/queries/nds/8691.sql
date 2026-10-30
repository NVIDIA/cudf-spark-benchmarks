
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS item_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity_sold > 100
)
SELECT 
    ti.item_rank,
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    COUNT(DISTINCT cd.c_customer_sk) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT cd.total_orders) AS count_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
FROM 
    TopItems ti
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN 
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
GROUP BY 
    ti.item_rank, ti.ws_item_sk, ti.total_quantity_sold, ti.total_sales_amount, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
ORDER BY 
    ti.item_rank
LIMIT 10;
