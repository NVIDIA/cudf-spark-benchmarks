
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    ORDER BY 
        total_cost DESC
    LIMIT 5
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 10
),
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    r.nation_name,
    co.order_count,
    oli.revenue
FROM 
    RankedSuppliers r
JOIN 
    CustomerOrderCount co ON r.s_suppkey = co.c_custkey
JOIN 
    OrderLineItem oli ON co.order_count = oli.o_orderkey
ORDER BY 
    r.total_cost DESC, co.order_count DESC
LIMIT 10;
