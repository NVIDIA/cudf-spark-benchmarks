WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_custkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        COALESCE(o.total_orders, 0) AS total_orders, 
        COALESCE(o.total_revenue, 0) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        OrderStats o ON c.c_custkey = o.o_custkey
)

SELECT 
    cs.c_custkey, 
    cs.c_name, 
    ss.s_name AS supplier_name, 
    ss.nation AS supplier_nation, 
    cs.total_orders, 
    cs.total_revenue, 
    ss.total_supplycost, 
    ss.total_parts
FROM 
    CustomerStats cs
JOIN 
    SupplierStats ss ON cs.total_orders > 0
ORDER BY 
    cs.total_revenue DESC, ss.total_supplycost DESC
LIMIT 100;