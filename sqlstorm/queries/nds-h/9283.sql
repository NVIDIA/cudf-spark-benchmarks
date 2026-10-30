WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey
),
RegionalSales AS (
    SELECT 
        n.n_regionkey,
        SUM(ss.total_sales) AS region_sales,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    rs.region_sales,
    rs.supplier_count,
    (SELECT SUM(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'O') AS total_open_orders,
    (SELECT COUNT(*) FROM RankedOrders o WHERE o.order_rank <= 10) AS top_order_count
FROM 
    region r
JOIN 
    RegionalSales rs ON r.r_regionkey = rs.n_regionkey
ORDER BY 
    rs.region_sales DESC, rs.supplier_count ASC;