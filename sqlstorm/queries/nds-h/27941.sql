WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), NotableRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 2
)
SELECT 
    rs.s_name AS supplier_name,
    rs.total_supplycost,
    c.c_name AS customer_name,
    c.order_count,
    nr.r_name AS region_name,
    nr.nation_count
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrderCounts c ON rs.rank = 1
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    NotableRegions nr ON n.n_regionkey = nr.r_regionkey
ORDER BY 
    rs.total_supplycost DESC, c.order_count DESC;
