WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
), 
SupplierPerformance AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.ps_availqty) AS total_avail_qty,
        AVG(rs.ps_supplycost) AS avg_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.ps_partkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name, ns.n_name
)

SELECT 
    rp.region_name,
    rp.nation_name,
    rp.supplier_count,
    rp.total_avail_qty,
    rp.avg_supply_cost,
    COALESCE(roc.total_order_value, 0) AS total_recent_order_value
FROM 
    SupplierPerformance rp
LEFT JOIN 
    (
        SELECT 
            r.r_name AS region_name,
            SUM(roc.total_order_value) AS total_order_value
        FROM 
            RecentOrders roc
        JOIN 
            customer c ON roc.o_custkey = c.c_custkey
        JOIN 
            nation ns ON c.c_nationkey = ns.n_nationkey
        JOIN 
            region r ON ns.n_regionkey = r.r_regionkey
        GROUP BY 
            r.r_name
    ) roc ON rp.region_name = roc.region_name
ORDER BY 
    rp.region_name, rp.nation_name;