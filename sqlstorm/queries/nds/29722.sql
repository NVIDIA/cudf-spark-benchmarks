
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country 
    FROM 
        customer c 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), Item_Sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount 
    FROM 
        web_sales ws 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    GROUP BY 
        ws.ws_bill_customer_sk, i.i_item_desc
), Top_Items AS (
    SELECT 
        ws_bill_customer_sk, 
        i_item_desc,
        total_quantity_sold,
        total_sales_amount,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY total_sales_amount DESC) AS item_rank
    FROM 
        Item_Sales
), Customer_Purchase_Summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ti.i_item_desc,
        ti.total_sales_amount,
        ti.total_quantity_sold
    FROM 
        Customer_Info ci
    JOIN 
        Top_Items ti ON ci.c_customer_sk = ti.ws_bill_customer_sk
    WHERE 
        ti.item_rank <= 5
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    ca_country, 
    i_item_desc, 
    total_sales_amount, 
    total_quantity_sold 
FROM 
    Customer_Purchase_Summary
ORDER BY 
    full_name, total_sales_amount DESC;
