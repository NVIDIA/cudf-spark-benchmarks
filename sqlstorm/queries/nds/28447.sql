
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        it.total_qty,
        it.total_sales,
        ROW_NUMBER() OVER (ORDER BY it.total_sales DESC) AS sales_rank
    FROM item i
    JOIN ItemSales it ON i.i_item_sk = it.ws_item_sk
    WHERE it.total_sales > 1000
),
CustomerSales AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ti.i_item_desc,
        si.ss_sold_date_sk,
        si.ss_ticket_number,
        si.ss_sales_price,
        si.ss_net_paid
    FROM CustomerInfo ci
    JOIN store_sales si ON ci.c_customer_sk = si.ss_customer_sk
    JOIN TopItems ti ON si.ss_item_sk = ti.i_item_sk
)
SELECT 
    cs.full_name,
    cs.i_item_desc,
    COUNT(cs.ss_ticket_number) AS total_purchases,
    SUM(cs.ss_sales_price) AS total_sales_price,
    SUM(cs.ss_net_paid) AS total_net_paid,
    ci.ca_city,
    ci.ca_state
FROM CustomerSales cs
JOIN CustomerInfo ci ON cs.c_customer_sk = ci.c_customer_sk
GROUP BY 
    cs.full_name, 
    cs.i_item_desc, 
    ci.ca_city, 
    ci.ca_state
ORDER BY total_sales_price DESC
LIMIT 10;
