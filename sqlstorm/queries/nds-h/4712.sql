WITH SupplierOrder AS (
    SELECT 
        s.s_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(lo.l_extendedprice * (1 - lo.l_discount)) DESC) AS rank_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem lo ON ps.ps_partkey = lo.l_partkey
    JOIN 
        orders o ON lo.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_name,
        total_revenue,
        total_orders
    FROM 
        SupplierOrder
    WHERE 
        rank_revenue <= 5
),
RegionDetails AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    ts.s_name AS supplier_name,
    ts.total_revenue,
    ts.total_orders,
    rd.nation_name,
    rd.region_name,
    rd.total_customers
FROM 
    TopSuppliers ts
LEFT JOIN 
    RegionDetails rd ON ts.s_name = rd.region_name
WHERE 
    ts.total_revenue IS NOT NULL
ORDER BY 
    ts.total_revenue DESC
LIMIT 10;