
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPriceSummary AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ps.total_supplycost) AS total_cost
    FROM 
        SupplierPriceSummary ps
    JOIN 
        nation n ON ps.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(ps.total_supplycost) > 10000
)
SELECT 
    ro.o_orderkey,
    ro.o_totalprice,
    la.total_sales,
    la.avg_quantity,
    ts.n_name AS top_supplier_nation,
    ts.total_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemAnalysis la ON ro.o_orderkey = la.l_orderkey
FULL OUTER JOIN 
    TopSuppliers ts ON ts.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = 1)
WHERE 
    ro.rank <= 5
ORDER BY 
    ro.o_totalprice DESC, la.total_sales DESC;
