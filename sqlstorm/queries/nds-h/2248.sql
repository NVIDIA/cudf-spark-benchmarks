
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT 
        sd.s_name, 
        sd.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sd.total_supply_cost DESC) AS SupplierRank
    FROM 
        SupplierDetails sd
)

SELECT 
    r.n_name AS nation_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_orders_revenue,
    COUNT(DISTINCT rs.s_name) AS supplier_count,
    RANK() OVER (ORDER BY COALESCE(SUM(od.total_revenue), 0) DESC) AS revenue_rank
FROM 
    nation r
LEFT JOIN 
    supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_name = s.s_name
LEFT JOIN 
    OrderDetails od ON ps.ps_partkey = od.o_orderkey
WHERE 
    (rs.SupplierRank <= 5 OR rs.SupplierRank IS NULL)
GROUP BY 
    r.n_name, rs.SupplierRank
HAVING 
    COALESCE(SUM(od.total_revenue), 0) > 0 OR COUNT(rs.s_name) = 0
ORDER BY 
    revenue_rank;
