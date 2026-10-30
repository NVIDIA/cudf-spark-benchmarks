WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supplycost,
        RANK() OVER (ORDER BY sd.total_supplycost DESC) AS rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supplycost IS NOT NULL
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    o.total_revenue,
    ts.total_supplycost
FROM 
    RankedOrders o
LEFT JOIN 
    TopSuppliers ts ON o.o_orderkey = ts.s_suppkey
WHERE 
    o.total_revenue > 10000
  AND 
    ts.rank IS NULL OR ts.rank <= 10
ORDER BY 
    o.o_orderdate DESC, total_revenue DESC;