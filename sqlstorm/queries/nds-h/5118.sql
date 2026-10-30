WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.nation,
        total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM 
        SupplierSummary s
)
SELECT 
    t.s_name,
    t.nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    MAX(o.o_totalprice) AS max_order_total
FROM 
    TopSuppliers t
JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    t.rank <= 10
GROUP BY 
    t.s_name, t.nation
ORDER BY 
    total_revenue DESC;
