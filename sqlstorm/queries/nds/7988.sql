
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_ext_tax) AS total_tax,
        CAST(d.d_date AS DATE) AS sale_date
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws_item_sk, CAST(d.d_date AS DATE)
),
top_items AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        ss.total_quantity,
        ss.total_sales
    FROM
        sales_summary ss
    JOIN
        item item ON ss.ws_item_sk = item.i_item_sk
    ORDER BY
        ss.total_sales DESC
    LIMIT 10
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_customer_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_summary ss ON ws.ws_item_sk = ss.ws_item_sk
    WHERE 
        ss.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        t.i_item_id AS item_id,
        t.i_product_name AS product_name,
        t.total_quantity,
        t.total_sales,
        ca.c_first_name,
        ca.c_last_name,
        ca.cd_gender,
        ca.cd_marital_status,
        ca.total_customer_sales
    FROM 
        top_items t
    JOIN 
        customer_analysis ca ON t.total_sales = ca.total_customer_sales
)
SELECT 
    fr.item_id,
    fr.product_name,
    fr.total_quantity,
    fr.total_sales,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status
FROM 
    final_report fr
WHERE 
    fr.total_sales > 1000
ORDER BY 
    fr.total_sales DESC;
