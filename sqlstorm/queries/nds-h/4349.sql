WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    WHERE 
        rs.supplier_rank = 1
    GROUP BY 
        rs.s_suppkey, rs.s_name
)
SELECT 
    r.r_name,
    ROUND(AVG(sd.total_cost), 2) AS avg_cost,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    COUNT(DISTINCT sd.s_suppkey) AS unique_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey = c.c_nationkey
WHERE 
    o.o_orderstatus = 'O' 
    AND os.lineitem_count > 0
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT sd.s_suppkey) > 5
ORDER BY 
    avg_cost DESC;
