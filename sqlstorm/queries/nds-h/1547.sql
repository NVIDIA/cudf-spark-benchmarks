WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > 1000.00
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    cs.order_count,
    cs.avg_order_value,
    ss.part_count,
    ss.total_available,
    ts.supplier_rank
FROM 
    RankedOrders o
JOIN 
    CustomerSummary cs ON o.o_orderkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
LEFT JOIN 
    TopSuppliers ts ON ss.part_count > 0
WHERE 
    o.total_revenue > 5000
ORDER BY 
    o.o_orderdate DESC, 
    cs.order_count DESC;