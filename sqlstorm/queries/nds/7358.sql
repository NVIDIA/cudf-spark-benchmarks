
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND w.web_state = 'CA'
        AND ws.ws_sold_date_sk BETWEEN 2459001 AND 2459357
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        r.total_discount,
        r.total_tax
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_sales,
    ts.total_discount,
    ts.total_tax,
    (ts.total_sales - ts.total_discount + ts.total_tax) AS net_revenue
FROM 
    top_sales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
ORDER BY 
    net_revenue DESC;
