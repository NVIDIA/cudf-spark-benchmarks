
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
        COALESCE(sd.total_profit, 0) AS total_profit,
        sd.sales_rank
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        (i.i_color LIKE '%Red%' OR i.i_color LIKE '%Blue%')
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ROW_NUMBER() OVER (ORDER BY SUM(sd.total_profit) DESC) AS customer_rank
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        SalesData sd ON ws.ws_item_sk = sd.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.ca_city, ci.ca_state
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.ca_state,
    id.i_item_desc,
    id.i_brand,
    id.total_quantity_sold,
    id.total_profit
FROM 
    TopCustomers tc
JOIN 
    ItemDetails id ON tc.customer_rank <= 10 AND id.total_quantity_sold > 100
ORDER BY 
    tc.customer_rank, id.total_profit DESC;
