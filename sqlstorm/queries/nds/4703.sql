
WITH ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) as sales_rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
), 
TopSellingItems AS (
    SELECT 
        item_sales.i_item_sk,
        item_sales.i_item_desc,
        item_sales.total_sales_quantity,
        item_sales.total_net_paid
    FROM 
        ItemSales item_sales 
    WHERE 
        item_sales.sales_rank <= 10
), 
CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    ti.i_item_desc,
    ti.total_sales_quantity,
    ti.total_net_paid,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown' 
    END AS gender,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = ti.i_item_sk) AS store_sales_count,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_item_sk = ti.i_item_sk) AS web_sales_count
FROM 
    TopSellingItems ti
JOIN 
    CustomerAddressDetails c ON c.c_customer_sk = ti.i_item_sk
LEFT JOIN 
    customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
WHERE
    c.ca_state IS NOT NULL
ORDER BY 
    ti.total_net_paid DESC;
