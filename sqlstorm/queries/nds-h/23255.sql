WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
), 
AggregateData AS (
    SELECT 
        COUNT(o.o_orderkey) AS order_count,
        AVG(revenue) AS avg_revenue,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        FilteredOrders o
    WHERE 
        o.o_totalprice IS NOT NULL
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    r.r_name,
    s.s_name,
    SUM(ad.total_sales) AS total_sales_by_supplier,
    COUNT(DISTINCT od.o_orderkey) AS order_count_by_supplier,
    MAX(s.s_acctbal) FILTER (WHERE s.s_acctbal > 1000) AS max_acctbal_above_1000
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_suppkey
LEFT JOIN 
    AggregateData ad ON s.s_suppkey = ad.order_count
RIGHT JOIN 
    FilteredOrders od ON od.o_orderkey = s.s_suppkey
WHERE 
    r.r_name LIKE '%east%' OR ad.avg_revenue IS NULL
GROUP BY 
    r.r_name, s.s_name
HAVING 
    COUNT(od.o_orderkey) > 10 OR MAX(s.s_acctbal) IS NULL
ORDER BY 
    total_sales_by_supplier DESC, r.r_name DESC;
