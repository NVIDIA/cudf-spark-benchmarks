WITH SupplierTotals AS (
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
        o.o_totalprice,
        SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        o.o_orderdate,
        s.s_name AS supplier_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, s.s_name
),
RegionNation AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    rt.region_name,
    rt.nation_name,
    SUM(od.total_line_value) AS total_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    AVG(st.total_supply_cost) AS avg_supplier_cost
FROM 
    RegionNation rt
JOIN 
    OrderDetails od ON rt.nation_name = od.supplier_name
JOIN 
    SupplierTotals st ON st.s_name = od.supplier_name
GROUP BY 
    rt.region_name, rt.nation_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;