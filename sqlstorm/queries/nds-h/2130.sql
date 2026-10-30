WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplyvalue,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_price,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supplyvalue,
        ss.part_count,
        NTILE(5) OVER (ORDER BY ss.total_supplyvalue DESC) AS supply_rank
    FROM 
        SupplierStats ss
)

SELECT 
    ns.n_name AS nation,
    rs.s_name AS supplier,
    rs.total_supplyvalue,
    ao.total_order_value,
    ao.avg_order_price,
    ns.total_sales,
    rs.part_count
FROM 
    RankedSuppliers rs
LEFT JOIN 
    AggregatedOrders ao ON ao.distinct_parts > rs.part_count
LEFT JOIN 
    NationSales ns ON rs.s_suppkey = ns.n_nationkey
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    ns.total_sales DESC, rs.total_supplyvalue ASC;