
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND c.c_acctbal > 1000
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY SUM(sc.total_supply_cost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(sc.total_supply_cost) > 5000
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice, 
    r.c_name, 
    r.c_acctbal, 
    ts.s_name AS top_supplier,
    COALESCE(ts.supplier_rank, 0) AS supplier_rank
FROM 
    RankedOrders r
LEFT JOIN 
    TopSuppliers ts ON r.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_discount > 0.1 AND l.l_quantity > 10)
WHERE
    r.order_rank <= 5
    AND r.o_totalprice IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
