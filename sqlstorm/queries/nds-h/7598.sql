WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice,
        s.s_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31' 
        AND c.c_mktsegment = 'BUILDING'
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.total_parts,
        s.total_cost,
        RANK() OVER (ORDER BY s.total_cost DESC) AS rank
    FROM 
        SupplierStats s
)
SELECT 
    od.o_orderkey,
    od.o_totalprice,
    od.l_quantity,
    od.l_extendedprice,
    ts.s_name AS supplier_name,
    ts.total_cost
FROM 
    OrderDetails od
JOIN 
    TopSuppliers ts ON od.s_name = ts.s_name
WHERE 
    ts.rank <= 5
ORDER BY 
    od.o_totalprice DESC, ts.total_cost DESC;