WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus = 'O'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, p.p_name, s.s_nationkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    spd.p_name,
    spd.total_quantity,
    spd.total_cost
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN 
    SupplierPartDetails spd ON r.o_orderkey = spd.ps_partkey
WHERE 
    (spd.total_quantity IS NOT NULL OR cs.total_orders > 0)
    AND r.OrderRank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_orderpriority;