
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_returns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, 
        wr_returning_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
popular_items AS (
    SELECT 
        sc.ws_item_sk, 
        i.i_item_desc, 
        s.s_store_name,
        SUM(sc.ws_quantity) AS total_sales,
        SUM(sc.ws_net_paid) AS total_sales_value
    FROM 
        web_sales sc
    JOIN 
        item i ON sc.ws_item_sk = i.i_item_sk
    JOIN 
        store s ON sc.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        sc.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        sc.ws_item_sk, i.i_item_desc, s.s_store_name
    HAVING 
        SUM(sc.ws_quantity) > 100
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(cr.total_return_quantity, 0) AS customer_returns,
    pi.total_sales,
    pi.total_sales_value,
    si.total_quantity,
    si.total_net_paid
FROM 
    customer_info ci
LEFT JOIN 
    customer_returns cr ON ci.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    popular_items pi ON ci.c_customer_sk = pi.ws_item_sk
LEFT JOIN 
    sales_cte si ON pi.ws_item_sk = si.ws_item_sk AND si.rank = 1
WHERE 
    ci.total_returns IS NOT NULL
ORDER BY 
    pi.total_sales_value DESC 
LIMIT 100;
