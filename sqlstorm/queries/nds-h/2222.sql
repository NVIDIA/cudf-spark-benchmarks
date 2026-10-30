WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        n.n_name
),
SalesRank AS (
    SELECT 
        nation_name,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supply_sources
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_acctbal
)

SELECT
    sr.nation_name,
    sr.total_sales,
    sr.total_orders,
    sr.sales_rank,
    ss.supplier_name,
    ss.s_acctbal,
    ss.total_available_qty,
    ss.supply_sources
FROM 
    SalesRank sr
LEFT JOIN 
    SupplierStats ss ON sr.sales_rank = ss.supply_sources
WHERE 
    sr.total_sales > 10000 
    AND (ss.s_acctbal IS NULL OR ss.s_acctbal > 5000)
ORDER BY 
    sr.sales_rank, ss.total_available_qty DESC;