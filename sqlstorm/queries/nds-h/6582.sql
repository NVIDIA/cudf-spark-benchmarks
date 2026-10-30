
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        EXTRACT(YEAR FROM o.o_orderdate) = 1997
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name,
        o.supplier_name
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 5
)

SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name AS customer_name,
    t.supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(l.l_extendedprice * (1 - l.l_discount) * l.l_tax) AS total_tax_collected
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.c_name, t.supplier_name
ORDER BY 
    t.o_orderdate DESC, total_revenue DESC;
