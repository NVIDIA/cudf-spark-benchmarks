WITH OrderSums AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_name AS nation_name,
        os.total_sales,
        os.order_count
    FROM 
        nation n
    JOIN 
        OrderSums os ON n.n_nationkey = os.c_nationkey
),
TopNations AS (
    SELECT 
        nation_name, 
        total_sales, 
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_sales,
        RANK() OVER (ORDER BY order_count DESC) AS rank_orders
    FROM 
        NationSales
)

SELECT 
    nation_name,
    total_sales,
    order_count,
    rank_sales,
    rank_orders
FROM 
    TopNations
WHERE 
    rank_sales <= 5 OR rank_orders <= 5
ORDER BY 
    total_sales DESC, 
    order_count DESC;