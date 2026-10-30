WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(s.total_parts, 0) AS total_parts,
    COALESCE(s.avg_supplycost, 0.00) AS avg_supplycost,
    r.o_orderkey,
    r.total_revenue
FROM 
    customer c
LEFT JOIN 
    CustomerStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    SupplierStats s ON s.total_parts > 0
JOIN 
    RankedOrders r ON r.rn <= 5
WHERE 
    (cs.total_spent > 1000 OR cs.total_orders > 10)
    AND (s.total_parts IS NULL OR s.avg_supplycost < 50)
ORDER BY 
    total_spent DESC, total_orders ASC;
