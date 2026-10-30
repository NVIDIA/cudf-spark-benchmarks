
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
top_selling_items AS (
    SELECT 
        sales_data.ws_item_sk,
        sales_data.total_quantity,
        sales_data.total_profit,
        item.i_item_desc
    FROM 
        sales_data
    JOIN 
        item ON sales_data.ws_item_sk = item.i_item_sk
    WHERE 
        sales_data.item_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_addr_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
purchase_patterns AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.hd_income_band_sk,
        ci.total_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_item_sk IN (SELECT ws_item_sk FROM top_selling_items) THEN ws.ws_order_number END) AS orders_for_top_items
    FROM 
        customer_info ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.cd_gender, ci.hd_income_band_sk, ci.total_orders
)
SELECT 
    pp.c_customer_sk,
    pp.cd_gender,
    pp.hd_income_band_sk,
    pp.total_orders,
    pp.orders_for_top_items,
    ROUND((pp.orders_for_top_items / NULLIF(pp.total_orders, 0)::decimal) * 100, 2) AS percentage_of_top_item_orders
FROM 
    purchase_patterns pp
WHERE 
    (pp.orders_for_top_items > 5 OR pp.cd_gender = 'F')  
ORDER BY 
    percentage_of_top_item_orders DESC;
