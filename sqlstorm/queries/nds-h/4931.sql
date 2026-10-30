WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        l.l_suppkey
),
HighValueSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        ts.total_sales
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE 
        rs.rank <= 5
),
FinalResults AS (
    SELECT 
        hvs.s_suppkey,
        hvs.s_name,
        COALESCE(hvs.total_sales, 0) AS total_sales,
        p.p_name,
        p.p_retailprice
    FROM 
        HighValueSuppliers hvs
    LEFT JOIN 
        partsupp ps ON hvs.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    fr.s_suppkey,
    fr.s_name,
    fr.total_sales,
    fr.p_name,
    fr.p_retailprice,
    CASE 
        WHEN fr.total_sales = 0 THEN 'No Sales'
        ELSE 'Active'
    END AS supplier_status
FROM 
    FinalResults fr
WHERE 
    fr.total_sales IS NOT NULL
ORDER BY 
    fr.total_sales DESC, fr.s_name;