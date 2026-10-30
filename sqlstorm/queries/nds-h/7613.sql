WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost,
    ts.part_count
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    r.rn <= 5 AND ts.rank <= 10
ORDER BY 
    r.o_orderdate DESC, ts.total_supply_cost DESC;
