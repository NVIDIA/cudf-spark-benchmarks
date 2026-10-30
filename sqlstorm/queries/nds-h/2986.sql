WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)

SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    MAX(rn) AS highest_priority_order,
    ps.total_available,
    ps.avg_supply_cost
FROM 
    CustomerOrderDetails c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    FilteredSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN 
    SupplierPartDetails ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    c.c_name, ps.total_available, ps.avg_supply_cost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 AND ps.total_available < 50
ORDER BY 
    total_revenue DESC;