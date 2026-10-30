
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS yearly_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
TopSuppliers AS (
    SELECT 
        ty.s_suppkey,
        ty.s_name,
        ty.total_available_qty 
    FROM 
        SupplierSummary ty
    WHERE 
        ty.total_available_qty > (SELECT AVG(total_available_qty) FROM SupplierSummary)
)
SELECT 
    oa.o_orderkey,
    oa.o_orderdate,
    oa.o_totalprice,
    COALESCE(ts.total_available_qty, 0) AS supplier_available_qty,
    COALESCE(ts.s_name, 'Not Applicable') AS supplier_name,
    oa.yearly_rank
FROM 
    OrderAnalysis oa
LEFT JOIN 
    lineitem l ON oa.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    oa.yearly_rank <= 5
ORDER BY 
    oa.o_orderdate DESC, 
    oa.o_orderkey;
