WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(od.total_revenue), 0) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSupplier AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS cost_rank
    FROM 
        SupplierStats ss
)
SELECT 
    ns.n_name,
    ns.total_sales,
    rs.s_name AS top_supplier,
    rs.total_cost,
    rs.part_count
FROM 
    NationSales ns
LEFT JOIN 
    RankedSupplier rs ON ns.total_sales > 0
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    ns.total_sales DESC, rs.total_cost DESC
LIMIT 10;
