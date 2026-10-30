
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
), 
CustomerRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
SalesSummary AS (
    SELECT 
        cr.r_regionkey,
        SUM(od.total_sale) AS region_sales
    FROM 
        OrderDetails od
    JOIN 
        CustomerRegion cr ON od.c_nationkey = cr.n_nationkey
    GROUP BY 
        cr.r_regionkey
)
SELECT 
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    ss.region_sales,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.s_acctbal) AS avg_supplier_balance
FROM 
    SalesSummary ss
LEFT JOIN 
    region r ON ss.r_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON ss.region_sales > 0 AND rs.supplier_rank = 1
GROUP BY 
    r.r_name, ss.region_sales
ORDER BY 
    ss.region_sales DESC NULLS LAST;
