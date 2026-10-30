WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
    ORDER BY 
        supplier_cost DESC
    LIMIT 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ts.s_name AS top_supplier,
    os.total_revenue,
    os.lineitem_count
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON ts.supplier_cost = (SELECT MAX(supplier_cost) FROM TopSuppliers)
JOIN 
    OrderStats os ON os.lineitem_count > 10
ORDER BY 
    os.total_revenue DESC, rp.total_supply_cost ASC
LIMIT 10;