
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
), 
PromotionalData AS (
    SELECT 
        p.p_promo_sk,
        SUM(ws.ws_net_profit) AS promo_profit,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_profit,
        sd.total_orders,
        COALESCE(pd.promo_profit, 0) AS promo_profit,
        COALESCE(pd.promo_orders, 0) AS promo_orders
    FROM 
        SalesData sd
    LEFT JOIN 
        PromotionalData pd ON sd.ws_item_sk = pd.p_promo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(cd.total_profit) AS total_profit,
    AVG(cd.total_sales) AS avg_sales_per_order,
    SUM(cd.promo_profit) AS total_promo_profit
FROM 
    CombinedData cd
JOIN 
    customer c ON cd.ws_item_sk = c.c_current_cdemo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 
    10;
