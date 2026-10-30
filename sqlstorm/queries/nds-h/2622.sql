WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        CTE_Customers.c_name,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    JOIN 
        customer CTE_Customers ON o.o_custkey = CTE_Customers.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),

TopOrders AS (
    SELECT 
        o_orderkey, 
        c_name, 
        o_orderdate, 
        o_totalprice
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)

SELECT 
    p.p_name,
    p.p_brand,
    SUM(ps.ps_supplycost * li.l_quantity) AS total_supply_cost,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    COALESCE(AVG(li.l_tax), 0) AS average_tax,
    COUNT(DISTINCT so.o_orderkey) AS total_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN 
    TopOrders so ON li.l_orderkey = so.o_orderkey
GROUP BY 
    p.p_name, 
    p.p_brand
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
