WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
TotalSales AS (
    SELECT 
        SUM(total_sales) AS overall_sales
    FROM 
        OrderSummary
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        AVG(s.s_acctbal) AS average_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)

SELECT 
    rs.r_name,
    rs.nation_count,
    rs.average_acctbal,
    (SELECT overall_sales FROM TotalSales) AS total_sales_in_1997,
    (SELECT COUNT(*) FROM RankedSuppliers WHERE rank = 1) AS top_supplier_count
FROM 
    RegionStats rs
WHERE 
    rs.average_acctbal IS NOT NULL
ORDER BY 
    rs.nation_count DESC, rs.average_acctbal DESC
LIMIT 5;