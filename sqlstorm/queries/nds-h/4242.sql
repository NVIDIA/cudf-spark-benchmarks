
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionStatistics AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(co.total_spent) AS region_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rs.r_name,
    rs.nation_count,
    COALESCE(s.total_sales, 0) AS total_supplier_sales,
    rs.region_sales
FROM 
    RegionStatistics rs
LEFT JOIN 
    SupplierSales s ON s.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE 
            l.l_shipdate >= DATE '1997-01-01'
            AND l.l_shipdate < DATE '1998-01-01'
        GROUP BY 
            ps.ps_suppkey
        ORDER BY 
            SUM(l.l_extendedprice) DESC
        LIMIT 1
    )
ORDER BY 
    rs.region_sales DESC, 
    rs.nation_count DESC;
