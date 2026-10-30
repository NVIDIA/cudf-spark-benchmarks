WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.num_parts,
        ss.total_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.num_parts > 5
)
SELECT 
    RO.o_orderkey,
    RO.o_orderdate,
    RO.o_totalprice,
    TS.s_suppkey,
    TS.s_name,
    TS.num_parts,
    TS.total_cost
FROM 
    RankedOrders RO
LEFT JOIN 
    lineitem LI ON RO.o_orderkey = LI.l_orderkey
LEFT JOIN 
    TopSuppliers TS ON LI.l_suppkey = TS.s_suppkey
WHERE 
    TS.supplier_rank IS NOT NULL 
    AND RO.order_rank <= 10
ORDER BY 
    RO.o_orderdate, TS.total_cost DESC;