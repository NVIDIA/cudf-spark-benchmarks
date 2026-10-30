WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= DATE '1996-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY SUM(ls.l_extendedprice * (1 - ls.l_discount)) DESC) AS rank
    FROM 
        lineitem ls
    JOIN 
        supplier s ON ls.l_suppkey = s.s_suppkey
    WHERE 
        ls.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    ts.s_name AS top_supplier_name,
    ts.s_acctbal AS top_supplier_acctbal
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierCosts s ON r.o_orderkey = s.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON r.o_orderkey = ts.s_suppkey
WHERE 
    (r.o_totalprice > (SELECT AVG(o_totalprice) FROM RankedOrders) OR ts.rank IS NOT NULL)
    AND r.rn <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;